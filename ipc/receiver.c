#include <stdio.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <unistd.h>
#include <fcntl.h>
#include <semaphore.h>
#include <sys/stat.h>
#include <stdlib.h>
#include <signal.h>
#include <string.h>

#define RING_LEN 255

struct shm_data_t {
	char data[RING_LEN][1024];
	int capacity;
	int length;
	int start; // read index
	int end_idx; // write index
};
#define SEM_NAME "mysem"
#define SEM_MUTEX "sem_mutex"

int main() {
	int shm_fd;
	struct shm_data_t *shm_data;
	int shm_size = sizeof(struct shm_data_t);


	// create semaphore
	sem_t *sem_id =sem_open(SEM_NAME, O_CREAT, S_IRUSR | S_IWUSR, 0);
	sem_t *sem_mutex = sem_open(SEM_MUTEX, O_CREAT, S_IRUSR | S_IWUSR, 1);

	// create shared memory
	shm_fd = shm_open("myshm",  O_CREAT | O_RDWR, S_IRWXU | S_IRWXG);
	if (shm_fd < 0) {
		perror("in shmopen");
		exit(1);
	}

	printf("shm_size=%d\n", shm_size);

	ftruncate(shm_fd, shm_size);

	// map the memory
	shm_data = (struct shm_data_t *)mmap(NULL, shm_size, PROT_READ | PROT_WRITE, MAP_SHARED, shm_fd, 0);
	if (shm_data == NULL) {
		perror("mmap failed");
		exit(1);
	}

	// write data
	int i = 0;
	shm_data->capacity = RING_LEN;
	shm_data->length = 0;
	char data[1024];
	for (i = 0; i < 10000; i++) {
		sem_wait(sem_id);
		sem_wait(sem_mutex);
		
		memcpy(data, shm_data->data[shm_data->start], 1024);
		shm_data->start = (shm_data->start + 1) % RING_LEN;
		shm_data->length = shm_data->length -1;
		
		sem_post(sem_mutex);
	}
	printf("got 10000 data\n");
	fflush(stdout);
	
	if (shm_unlink("/myshm") != 0) {
		perror("shmunlink failed");
		exit(1);
	}

	if (sem_unlink(SEM_NAME) != 0) {
		perror("sem_unlink failed");
		exit(1);
	}
	if (sem_unlink(SEM_MUTEX) != 0) {
		perror("sem_unlink failed");
		exit(1);
	}
	return 0;
}
