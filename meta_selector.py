import os
import re
from typing import List, Dict
import subprocess
from urllib import request
from hashlib import sha256


class Sdk:
    def __init__(self, filename: str, name: str, major: str, minor: str, patch):
        self.filename = filename
        self.name = name
        self.major = major
        self.minor = minor
        self.patch = patch
        self.fullname = filename.replace(".rb", "");

    def is_newer_than(self, other):
        if self.major > other.major:
            return True
        if self.minor > other.minor:
            return True
        if self.patch > other.patch:
            return True
        return False


class MetaSelector:
    quiet = False

    __keep_line_matchers = [
        re.compile("^\\s*arch\\b.*"),
        re.compile("^\\s*version\\b.*"),
        re.compile("^\\s*name\\b.*"),
        re.compile("^\\s*desc\\b.*"),
        re.compile("^\\s*depends_on\\b.*")
    ]
    __url_vars = [
        "url",
        "url_x64",
        "url_arm64"
    ]

    def __init__(self, workdir):
        self.workdir = workdir
        pass

    def run(self):
        files = self.list_work_files()
        lookup = self.generate_version_lookup(files)
        for key in lookup:
            sdk = lookup[key]
            self.create_meta_package_from(sdk)

    def create_meta_package_from(self, sdk: Sdk) -> None:
        source_path = os.path.join(self.workdir, sdk.filename)
        output: List[str] = [
            "cask \"{}\" do".format(sdk.name)
        ]
        set_url = False
        set_cask_dependency = False
        [user, repo] = self.parse_origin_remote()
        github_repo = f"https://github.com/{user}/{repo}"
        meta_artifact = f"{github_repo}/raw/master/META.md"
        sha256 = self.hash(meta_artifact)
        with open(source_path) as fp:
            lines = fp.readlines()
            assignment_re = re.compile("\\s*(?P<variable>[^\\s]+)\\s*=?\\s*(?P<value>.*)")
            last_var = ""
            for line in lines:
                line = line.rstrip()
                match = assignment_re.match(line)
                is_var_line = match is not None
                if is_var_line:
                    variable = match.group("variable")
                    is_new_variable = variable != last_var
                    have_prior_output = len(output) > 0
                    last_line_is_blank = output[-1] == ""
                    if is_new_variable and have_prior_output and not last_line_is_blank:
                        output.append("")
                    last_var = variable

                    if variable in self.__url_vars and set_url is False:
                        output.append(f"  url \"{meta_artifact}\"")
                        output.append(f"  sha256 \"{sha256}\"")
                        set_url = True
                    elif variable == "depends_on":
                        if not set_cask_dependency:
                            output.append(f"  depends_on cask: \"{sdk.fullname}\"")
                        # include the original line
                        # include the dependency on the dotnet cask
                    elif variable == "homepage":
                        output.append(f"  homepage \"{github_repo}\"")

                if self.should_keep_line(line):
                    output.append(line)
                    continue
            # the meta package contains no activatable artifacts
            # -> according to https://github.com/krema/homebrew-cask-local/blob/master/doc/cask_language_reference/all_stanzas.md
            #    we can set stage_only: true
            #    otherwise the verification workflows will fail with "at least one activatable artifact stanza is required"
            output.append("  stage_only true")
            output.append("end")

        self.log("creating meta-package: {}".format(source_path))
        target_path = "{}.rb".format(os.path.join(self.workdir, sdk.name))
        with open(target_path, "w") as fp:
            fp.writelines(f"{s}\n" for s in output)

    def hash(self, url: str) -> str:
        req = request.urlopen(url)
        raw_data = req.read()
        result = sha256(raw_data)
        return result.hexdigest()

    __web_url_regex = re.compile(".*://(?P<host>[a-zA-Z0-9_.-]+)/(?P<user>[a-zA-Z0-9_.-]+)/(?P<repo>[a-zA-Z0-9_.-]+)")
    __git_url_regex = re.compile(".*@(?P<host>[a-zA-Z0-9_.-]+):(?P<user>[a-zA-Z0-9_.-]+)/(?P<repo>[a-zA-Z0-9_.-]+)")

    def parse_origin_remote(self) -> List[str]:
        # for now, hard-coded to return me and my repo
        # so I can manually test, but this should be
        # updated to read the info from git via the cli
        # or use environment variables perhaps?
        lines = [str(l) for l in subprocess.check_output("git remote -v").splitlines()]
        origin_lines = [l for l in lines if l.find("origin") > -1]
        if len(origin_lines) == 0:
            raise Exception("Unable to determine url for remote: origin")
        web_match = self.__web_url_regex.match(origin_lines[0])
        if web_match is not None:
            user = web_match.group("user")
            repo = web_match.group("repo")
            return [user, repo]
        git_match = self.__git_url_regex.match(origin_lines[0])
        if git_match is not None:
            user = git_match.group("user")
            repo = git_match.group("repo").replace(".git", "")
            return [user, repo]

        raise Exception("Unable to parse origin url: {}".format(origin_lines[0]))

    def log(self, s: str) -> None:
        if self.quiet:
            return
        print(s)

    @staticmethod
    def generate_version_lookup(files) -> Dict[str, Sdk]:
        regex = re.compile("(?P<name>dotnet-sdk)(?P<major>\\d+)-(?P<minor>\\d+)-(?P<patch>\\d+)")
        lookup = {}
        for f in files:
            match = regex.match(f)
            if match is None:
                print("ignored {}: No version match match for filename".format(f))
                continue

            major = match.group("major")
            name = "{}{}".format(match.group("name"), major)
            minor = match.group("minor")
            patch = match.group("patch")
            current = Sdk(f, name, major, minor, patch)

            if name not in lookup:
                lookup[name] = current
                continue

            existing = lookup[name]
            if current.is_newer_than(existing):
                lookup[name] = current
        return lookup

    def list_work_files(self):
        return [
            f for f in os.listdir(self.workdir)
            if os.path.isfile(os.path.join(self.workdir, f))
        ]

    def should_keep_line(self, line: str):
        for matcher in self.__keep_line_matchers:
            if matcher.match(line) is not None:
                return True
        return False


if __name__ == '__main__':
    workdir = os.path.join(os.path.dirname(__file__), "Casks")
    MetaSelector(workdir).run()
