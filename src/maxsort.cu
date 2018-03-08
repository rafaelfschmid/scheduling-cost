/**
 * Copyright 1993-2012 NVIDIA Corporation.  All rights reserved.
 *
 * Please refer to the NVIDIA end user license agreement (EULA) associated
 * with this source code for terms and conditions that govern your use of
 * this software. Any use, reproduction, disclosure, or distribution of
 * this software and related documentation outside the terms of the EULA
 * is strictly prohibited.
 */
#include <stdio.h>
#include <stdlib.h>

#include <iostream>
#include <algorithm>

#include <cuda.h>


struct Task {
	uint id;
	float time;

	Task(uint id, float time) {
		this->id = id;
		this->time = time;
	}

	Task() {
		this->id = 0;
		this->time = 0;
	}

	bool operator() (Task i,Task j) { return (i.time > j.time); }
};

struct Machine {
	int id;
	float cost;

	Machine() {
		this->id = 0;
		this->cost = 0;
	}

	bool operator() (Machine i,Machine j) { return (i.cost < j.cost); }
};

void min_min(Task* tasks, float* completion_times, int* task_map, bool* task_scheduled, Machine* machines,
		int t, int m, int max_time) {

	uint count = 0;
	uint q = 0;

	while(count < t) {

		float current_time = 0;

		int j = machines[q].id;
		int i = 0;

		while(count < t && i < t) {
			int task_id = tasks[j * t + i].id;

			if (!task_scheduled[task_id]) {
				current_time = completion_times[j] + tasks[j * t + i].time;

				if(current_time > max_time){
					i++;
					continue;
				}

				task_scheduled[task_id] = true;
				task_map[task_id] = j;
				completion_times[j] = current_time;
				count++;
			}
			i++;
		}

		q++;

		if(q == m && count != t) {
			printf("### ERROR ###\n");
		}
	}
}

void machine_sorting(Machine* machines, int m) {

	std::stable_sort (&machines[0], &machines[0]+m, Machine());
}

void segmented_sorting(Task* tasks, int m, int t) {

	for(int i = 0; i < m; i++) {
		int j = i*t;
		std::stable_sort (&tasks[j], &tasks[j]+t, Task());
	}
}

template<typename T>
void print(T* vec, uint t, uint m) {
	std::cout << "\n";
	for (uint i = 0; i < t; i++) {
		for (uint j = 0; j < m; j++) {
			std::cout << vec[i * m + j] << " ";
		}
		std::cout << "\n";
	}

}

template<typename T>
void print(T* vec, uint t) {
	std::cout << "\n";
	for (uint i = 0; i < t; i++) {
		std::cout << vec[i] << " ";
	}
	std::cout << "\n";
}

void print(Task* vec, uint t, uint m) {
	std::cout << "\n";
	for (uint j = 0; j < m; j++) {
		for (uint i = 0; i < t; i++) {
			std::cout << "id=" << vec[j * t + i].id << " time="
					<< vec[j * t + i].time << "\t";
		}
		std::cout << "\n";
	}
}


void print(Machine* vec, uint m) {
	std::cout << "\n";
	for (uint j = 0; j < m; j++) {
			std::cout << "id=" << vec[j].id << " time="
					<< vec[j].cost << "\t";
	}
	std::cout << "\n";
}

void print(float* completion_times, Machine* vec, uint m) {
	float sum = 0;
	for (uint j = 0; j < m; j++) {
		uint id = vec[j].id;
		float cost = vec[j].cost * completion_times[id];

		std::cout << vec[j].cost << " * " << completion_times[id] << " = " << cost << "\n";
		sum += cost;
	}
	std::cout << "Custo Total: " << sum << "\n";
}

int main(int argc, char **argv) {
	int t, m;
	float max_time, aux;

	aux = scanf("%d", &t);
	aux = scanf("%d", &m);
	aux = scanf("%f", &max_time);

	//std::cout << "t=" << t << " m=" << m << "\n";

	Task *tasks = (Task *) malloc(sizeof(Task) * (t * m));
	bool *task_scheduled = (bool *) malloc(sizeof(bool) * t);
	int *task_map = (int *) malloc(sizeof(int) * (t));
	float *completion_times = (float *) malloc(sizeof(float) * (m));
	Machine *machines = (Machine *) malloc(sizeof(Machine) * (m));

	// Read matrix task machine
	for (int i = 0; i < t; i++) {
		for (int j = 0; j < m; j++) {
			int a = scanf("%f", &aux);
			tasks[j * t + i].id = i;
			tasks[j * t + i].time = aux;
			completion_times[j] = 0;
		}
		task_map[i] = -1;
		task_scheduled[i] = false;
	}

	//print(tasks, t, m);

	// Reading vector of costs for each machine
	for (int j = 0; j < m; j++) {
		int a = scanf("%f", &aux);
		machines[j].id = j;
		machines[j].cost = aux;
	}

	cudaEvent_t start, stop;
	cudaEventCreate(&start);
	cudaEventCreate(&stop);

	cudaEventRecord(start);
	machine_sorting(machines, m);
	//print(machines, m);

	segmented_sorting(tasks, m, t);
	//print(tasks,t,m);

	min_min(tasks, completion_times, task_map, task_scheduled, machines, t, m, max_time);
	cudaEventRecord(stop);

	if (ELAPSED_TIME == 1) {
		cudaEventSynchronize(stop);
		float milliseconds = 0;
		cudaEventElapsedTime(&milliseconds, start, stop);
		std::cout << milliseconds << "\n";
	}
	else {
		//print(tasks, t, m);
		//print(completion_times, m);
		print(completion_times, machines, m);
		//print(task_scheduled, t);
		//print(task_map, t, m);
	}

	free(task_scheduled);
	free(task_map);
	free(tasks);
	free(completion_times);

	return 0;
}

