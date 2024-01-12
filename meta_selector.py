import os


class MetaSelector:
    def __init__(self, workdir):
        self.workdir = workdir
        pass

    def run(self):
        pass


if __name__ == '__main__':
    workdir = os.path.dirname(__file__)
    MetaSelector(workdir).run()
