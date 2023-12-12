import h5py
import argparse

def copy_dataset(source_file, destination_file, source_dataset, destination_dataset, overwrite):
    with h5py.File(source_file, 'r') as source:
        with h5py.File(destination_file, 'a') as destination:
            if source_dataset not in source:
                print(f"Dataset '{source_dataset}' does not exist in the source file.")
                return
            
            if destination_dataset in destination:
                if not overwrite:
                    print(f"Dataset '{destination_dataset}' already exists in the destination file. Skipping...")
                    return
                else:
                    print(f"Dataset '{destination_dataset}' already exists in the destination file. Overwriting...")
                    del destination[destination_dataset]
            
            source_dataset_obj = source[source_dataset]
            destination.create_dataset(destination_dataset, data=source_dataset_obj)
            print(f"Dataset '{source_dataset}' copied to '{destination_dataset}' successfully.")

def main():
    parser = argparse.ArgumentParser(description='Copy a dataset from one HDF5 file to another.')
    parser.add_argument('source_file', help='Path to the source HDF5 file')
    parser.add_argument('destination_file', help='Path to the destination HDF5 file')
    parser.add_argument('source_dataset', help='Name of the dataset in the source file')
    parser.add_argument('destination_dataset', help='Name of the dataset in the destination file')
    parser.add_argument('-o', '--overwrite', action='store_true', help='Overwrite the destination dataset if it already exists')
    args = parser.parse_args()

    copy_dataset(args.source_file, args.destination_file, args.source_dataset, args.destination_dataset, args.overwrite)

if __name__ == '__main__':
    main()
