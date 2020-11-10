from core import Environment, Mouse
from datetime import datetime
import h5py
import numpy as np
from tqdm import tqdm


def main(N_MICE):
    """
    function runs the simulation. Data are stored in a h5 file in the current
    directory

    Inputs
    ------
    N_MICE: (int) the number of mice to simulate

    """
    ENV_WIDTH = 250  # mm
    ENV_HEIGHT = 180  # mm
    AVG_SPEED = 0.09  # mm/ms
    SPEED_STD = 0.06  # mm/ms
    MAJOR_AXIS = 60  # mm
    MINOR_AXIS = 30  # mm

    env = Environment(ENV_WIDTH, ENV_HEIGHT)
    mice = [Mouse(env, N_MICE, i, avg_speed=AVG_SPEED,
                  speed_std=SPEED_STD, major_axis=MAJOR_AXIS,
                  minor_axis=MINOR_AXIS) for i in range(N_MICE)]

    # duration is chosen so movements are on avg 1/5 of body length
    movement_duration = (1/5)*(MAJOR_AXIS/mice[0].avg_speed)

    if N_MICE == 2:
        simulation_length_min = 5
    elif N_MICE == 3:
        simulation_length_min = 10
    else:
        simulation_length_min = 1

    simulation_length_ms = int(simulation_length_min*60*1000)
    simulation_length_ms = int(simulation_length_ms/movement_duration)

    # this loop runs the simulation
    for i in tqdm(range(simulation_length_ms)):
        # duration here is in ms
        for mouse in mice:
            mouse.move(movement_duration=movement_duration)

    # initialize arrays to store the data
    x_center_history, _, x_perimeter_history, _ = mice[0].get_position_history()
    center_history = np.zeros((len(x_center_history), N_MICE*2))
    perimeter_history = np.zeros(
        (len(x_perimeter_history), N_MICE*2, len(x_perimeter_history[0])))

    for i, mouse in enumerate(mice):
        # because there is an x and y column for each mouse
        i *= 2
        x_center_history, y_center_history, x_perimeter_history, y_perimeter_history = mouse.get_position_history()

        center_history[:, i] = x_center_history
        center_history[:, i+1] = y_center_history

        for timepoint in range(len(x_perimeter_history)):
            perimeter_history[timepoint, i, :] = x_perimeter_history[timepoint]
            perimeter_history[timepoint, i+1, :] = y_perimeter_history[timepoint]

    # build filename
    str_datetime = datetime.now().strftime('%m%d%Y_%H%M%S')
    if N_MICE == 1:
        filename = (f'{N_MICE}mouse_{simulation_length_min}'
                    f'min_{str_datetime}')
    else:
        filename = (f'{N_MICE}mice_{simulation_length_min}'
                    f'min_{str_datetime}')

    # save data to h5 file
    with h5py.File(filename, 'w') as f:
        positions = f.create_dataset('center_history', center_history.shape,
                                     dtype=float, data=center_history)
        f.create_dataset('perimeter_history',
                         perimeter_history.shape,
                         dtype=float, data=perimeter_history)
        positions.attrs['env_width'] = ENV_WIDTH
        positions.attrs['env_height'] = ENV_HEIGHT
        positions.attrs['n_mice'] = N_MICE
        positions.attrs['simulation_length_min'] = simulation_length_min
        positions.attrs['avg_speed'] = AVG_SPEED
        positions.attrs['speed_std'] = SPEED_STD
        positions.attrs['major_axis'] = MAJOR_AXIS
        positions.attrs['minor_axis'] = MINOR_AXIS


if __name__ == "__main__":
    simulation_rounds = 30

    for i in range(simulation_rounds):
        main(N_MICE=2)
