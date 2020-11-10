import h5py
import numpy as np
import matplotlib.pyplot as plt


# this script plots the mouse trajectories

# add the filename here
filename = ''

with h5py.File(filename, 'r') as f:
    center_history = f.get('center_history')
    positions = np.array(center_history)
    env_width = center_history.attrs['env_width']
    env_height = center_history.attrs['env_height']
    n_mice = center_history.attrs['n_mice']
    simulation_length_min = center_history.attrs['simulation_length_min']

    perimeter_history = f.get('perimeter_history')
    perimeter_history_np = np.array(perimeter_history)

for i in range(n_mice):
    i *= 2
    plt.plot(positions[:, i], positions[:, i+1])

plt.xlim((0, env_width))
plt.ylim((0, env_height))
if n_mice == 1:
    plt.title(f'{n_mice} mouse {simulation_length_min} minutes')
else:
    plt.title(f'{n_mice} mice {simulation_length_min} minutes')
plt.show()
