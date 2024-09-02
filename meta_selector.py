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

    __web_url_regex = re.compile(".*://(?P<host>[a-zA-Z0-9_.-]+)/(?P<user>[a-zA-Z0-9_.-]+)/(?P<repo>[a-zA-Z0-9_.-]+)")
    __git_url_regex = re.compile(".*@(?P<host>[a-zA-Z0-9_.-]+):(?P<user>[a-zA-Z0-9_.-]+)/(?P<repo>[a-zA-Z0-9_.-]+)")
    __git_ssh_regex = re.compile(".*://.*@(?P<host>[a-zA-Z0-9_.-]+)/(?P<user>[a-zA-Z0-9_.-]+)/(?P<repo>[a-zA-Z0-9_.-]+)")

    def __init__(self, workdir):
        self.workdir = workdir
        pass

    def run(self):
        files = self.list_work_files(self.workdir)
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
        [user, repo] = self.read_origin_remote()
        github_repo = f"https://github.com/{user}/{repo}"
        meta_artifact = f"{github_repo}/raw/master/META.md"
        with open(source_path) as fp:
            lines = fp.readlines()
            assignment_re = re.compile("\\s*(?P<variable>[^\\s]+)\\s*=?\\s*(?P<value>.*)")
            last_var = ""
            for line in lines:
                line = line.rstrip()
                looks_like_cask_def_start = line.startswith("cask") and line.endswith("do")
                match = assignment_re.match(line)
                is_var_line = not looks_like_cask_def_start and match is not None
                should_store_last_var = False
                variable = ""
                if is_var_line:
                    variable = match.group("variable")
                    is_new_variable = variable != last_var
                    have_prior_output = len(output) > 1  # should ignore the starting line too
                    last_line_is_blank = output[-1] == ""
                    if is_new_variable and have_prior_output and not last_line_is_blank:
                        if last_var not in ["version", "desc", "name"] and last_var not in self.__url_vars:
                            output.append("")

                    if variable in self.__url_vars and set_url is False:
                        output.append(f"  url \"{meta_artifact}\"")
                        set_url = True
                        should_store_last_var = True
                    elif variable == "depends_on":
                        if not set_cask_dependency:
                            output.append(f"  depends_on cask: \"{sdk.fullname}\"")
                        should_store_last_var = True
                    elif variable == "homepage":
                        output.append(f"  homepage \"{github_repo}\"")
                        should_store_last_var = True

                if self.should_keep_line(line):
                    output.append(line)
                    should_store_last_var = True
                    if variable == "version":
                        output.append(f"  sha256 :no_check")
                        output.append("")
                if should_store_last_var:
                    last_var = variable
                elif variable in self.__url_vars:
                    last_var = "url"
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

    def read_origin_remote(self) -> List[str]:
        lines = [str(l) for l in subprocess.check_output("git remote -v", shell=True).decode("utf-8").splitlines()]
        origin_lines = [l for l in lines if l.strip().startswith("origin")]
        if len(origin_lines) == 0:
            print(lines)
            print(origin_lines)
            raise Exception("Unable to determine url for remote: origin")
        parts = origin_lines[0].split()
        if parts[0] != "origin":
            raise Exception(
                f"Danger, Will Robinson: first non-whitespace part expected to be 'origin' for line {origin_lines[0]}")
        return self.parse_origin_remote(parts[1])

    def parse_origin_remote(self, line: str) -> List[str]:
        web_match = self.__web_url_regex.match(line)
        if web_match is not None:
            user = web_match.group("user")
            repo = web_match.group("repo")
            return [user, repo]

        git_match = self.__git_url_regex.match(line)
        if git_match is not None:
            user = git_match.group("user")
            repo = git_match.group("repo").replace(".git", "")
            return [user, repo]

        ssh_match = self.__git_ssh_regex.match(line)
        if ssh_match is not None:
            user = ssh_match.group("user")
            repo = ssh_match.group("repo").replace(".git", "")
            return [user, repo]

        raise Exception("Unable to parse origin url: {}".format(line))

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

    @staticmethod
    def list_work_files(workdir):
        return [
            f for f in os.listdir(workdir)
            if os.path.isfile(os.path.join(workdir, f))
        ]

    def should_keep_line(self, line: str):
        for matcher in self.__keep_line_matchers:
            if matcher.match(line) is not None:
                return True
        return False


if __name__ == '__main__':
    workdir = os.path.join(os.path.dirname(__file__), "Casks")
    MetaSelector(workdir).run()
