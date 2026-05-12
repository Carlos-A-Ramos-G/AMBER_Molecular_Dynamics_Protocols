#!/usr/bin/env python3
import numpy as np

replicas=5
WEIGHTS_9 = [0.04064, 0.09032, 0.13031, 0.15617, 0.16512, 0.15617, 0.13031, 0.09032, 0.04064]
WEIGHTS_12= [0.02359, 0.05347, 0.08004, 0.10158, 0.11675, 0.12457, 0.12457, 0.11675, 0.10158, 0.08004, 0.05347, 0.02359]
MODIFICATIONS = ['SYSTEM_NAME']
SYSTEMS = ['ligand','michaelis']


def get_filename(modification, system, replica, window):
    return f'{modification}/{system}/replica_{replica}/{window}/dvdl_{window}.dat'


def system_average(system, modification, weights=WEIGHTS_9):
    averages = []
    for replica in range(1, replicas + 1):
        data = [np.loadtxt(get_filename(modification, system, replica, window)) for window in range(1, len(weights) + 1)]
        mean = np.dot(np.mean(data, axis=1), weights)
        print(f'{system} replica {replica}: {mean:5.2f}')
        averages.append(mean)
    means = np.mean(averages)
    std = np.std(averages)
    print(f'mean for {system}: {means:5.2f} =/- {std:4.2f}')
    return means, std


def delta_delta_G(ligand, michaelis, modification, weights=WEIGHTS_9):
    delta_G_ligand = system_average(ligand, modification, weights)
    delta_G_michaelis = system_average(michaelis, modification, weights)
    ddG = delta_G_michaelis[0] - delta_G_ligand[0]
    error = (delta_G_michaelis[1]**2 + delta_G_ligand[1]**2)**(1/2)
    print (f'ddG for {modification}: {ddG:5.2f} +/- {error:4.2f}')

delta_delta_G(SYSTEMS[0],SYSTEMS[1], MODIFICATIONS[0])
