import json
import argparse


def merge(main_file, other_files, **kwargs):
    data = {}

    with open(main_file, mode='r') as file:
        data = json.load(file)

    for other_file in other_files:
        additional = {}

        with open(other_file, mode='r') as file:
            additional = json.load(file)

        data["require"].update(additional["require"])

    del data["extra"]["merge-plugin"]

    print(repr(data))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description='Merge composer.json files')
    parser.add_argument('main_file', metavar='composer.json', type=str, help='main composer.json file')
    parser.add_argument('other_files', metavar='composer.local.json', type=str, nargs='+', help='a composer.local.json file to merge')
    parser.add_argument('--output', metavar='output.json', type=str, default='composer.json', help='output file')

    args = parser.parse_args()
    merge(main_file=args.main_file, other_files=args.other_files)
