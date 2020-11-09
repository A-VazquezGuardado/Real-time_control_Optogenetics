import h5py
import numpy as np
import os
import core
from datetime import datetime
import sys


def is_interacting(reference_mouse_positions, other_mice_positions, threshold,
                   n_other_mice, major_axis):
    """
    determine if a mouse is interacting with any other mouse at a given
    timepoint. Ineffiecient solution

    Inputs
    ------
    reference_mouse_positions: (np array of shape 2, perimeter_resolution)
    other_mice_positions: (np array of shape n_other_mice*2,perimeter_resolution)
    threshold: (int) distance threshold in mm below which we consider the mice
               to be interacting
    n_other_mice: (int) how many other mice are in the arena
    major_axis: (int) length of major axis in mm

    Returns
    -------
    interacting: (bool) whether the given mouse is interacting with any other
                 mouse at the given timepoint
    """
    interacting = False

    for mouse in range(n_other_mice):
        mouse *= 2
        for i in range(reference_mouse_positions.shape[1]):
            for j in range(other_mice_positions.shape[1]):
                distance = np.linalg.norm(
                    [(reference_mouse_positions[0][i]
                     - other_mice_positions[mouse][j]),
                     (reference_mouse_positions[1][i]
                     - other_mice_positions[mouse+1][j])]
                )
                if distance < threshold:
                    return True
                elif distance > (2*major_axis + 2*threshold):
                    return False

    return interacting


def measure_interactions(n_mice, perimeter_history, threshold, major_axis):
    """
    determine if a mouse is interacting with any other mouse at a given
    timepoint

    Inputs
    ------
    n_mice: (int) how many mice were simulated
    perimeter_history: (np array
                        of shape n_timepoints,n_mice*2,perimeter_resolution)
                        each mouse's perimeter at each timepoint
    threshold: (int) distance threshold in mm below which we consider the mice
               to be interacting
    major_axis: (int) length of major axis in mm

    Returns
    -------
    (np array of shape n_mice) the percent of time each mouse was interacting
    """
    interacting = np.zeros((n_mice, perimeter_history.shape[0]))

    for mouse in range(n_mice):
        # since there is an x and y col for each mouse
        mouse_by2 = mouse*2

        for timepoint in tqdm(range(perimeter_history.shape[0])):
            interacting[mouse, timepoint] = is_interacting(
                perimeter_history[timepoint, mouse_by2:mouse_by2+2, :],
                np.delete(
                    perimeter_history[timepoint, :, :],
                    [mouse_by2, mouse_by2+1],
                    axis=0),
                threshold,
                n_mice-1,
                major_axis)

    return interacting.sum(axis=1) / interacting.shape[1]


def main(threshold):
    """
    main function to compute mouse interaction time for each simulation.
    Results are saved to a txt file in the current directory

    Inputs
    ------
    threshold: (int) distance threshold in mm below which we consider the mice
               to be interacting
    """
    files = os.listdir()
    sim_types = ['2', '3']

    # build filename
    str_datetime = datetime.now().strftime('%m%d%Y_%H%M%S')
    out_file = f'sim_results_{str_datetime}.txt'
    with open(out_file, 'w') as f:
        f.write('Simulation results\n')
        f.write(f'distance threshold {threshold} mm\n')

    for sim_type in sim_types:
        with open(out_file, 'a') as f:
            f.write(f'{sim_type} mice\n')

        for f in files:
            if f[0] == sim_type:
                print(f)
                with h5py.File(f, 'r') as f:
                    center_history_dataset = f.get('center_history')
                    n_mice = center_history_dataset.attrs['n_mice']
                    major_axis = center_history_dataset.attrs['major_axis']
                    perimeter_history = f.get('perimeter_history')
                    perimeter_history_np = np.array(perimeter_history)

                # calculate interaction %
                percent_interaction = measure_interactions(
                    n_mice, perimeter_history_np, threshold, major_axis)

                # append data to txt file
                with open(out_file, 'a') as f:
                    f.write(' '.join(str(i) for i in percent_interaction))
                    f.write('\n')


if __name__ == "__main__":
    threshold = int(sys.argv[1])  # mm
    main(threshold)
