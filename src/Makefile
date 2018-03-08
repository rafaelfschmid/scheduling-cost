libs=-I"../lib"
#caching global memory
#caching=-Xptxas -dlcm=ca
params=-std=c++11 --expt-extended-lambda -lcuda
gen=-gencode arch=compute_20,code=sm_20 -gencode arch=compute_30,code=sm_30 -gencode arch=compute_35,code=sm_35 -gencode arch=compute_37,code=sm_37 -gencode arch=compute_50,code=sm_50 -gencode arch=compute_52,code=sm_52 -gencode arch=compute_52,code=compute_52
segment=2

all: minmin minsort maxmin maxsort inorder

minmin: minmin.cu
	nvcc $(gen) -O3 minmin.cu -o minmin.exe $(libs) $(params) -DELAPSED_TIME=$(TIME)

minsort: minsort.cu
	nvcc $(gen) -O3 minsort.cu -o minsort.exe $(libs) $(params) -DELAPSED_TIME=$(TIME)

maxmin: maxmin.cu
	nvcc $(gen) -O3 maxmin.cu -o maxmin.exe $(libs) $(params) -DELAPSED_TIME=$(TIME)

maxsort: maxsort.cu
	nvcc $(gen) -O3 maxsort.cu -o maxsort.exe $(libs) $(params) -DELAPSED_TIME=$(TIME)

inorder: inorder.cu
	nvcc $(gen) -O3 inorder.cu -o inorder.exe $(libs) $(params) -DELAPSED_TIME=$(TIME)



