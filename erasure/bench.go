package main

import (
	"bytes"
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"sync"
	"time"
)

var (
	mode        = flag.String("mode", "invalid_mode", "test mode = save_serial, save_parallel, get_serial, get_parallel")
	num         = flag.Int("num", 200, "number of operations to made")
	viaNginx    = flag.Bool("via_nginx", false, "request via nginx, need to configure nginx")
	getBaseAddr = "http://127.0.0.1/get"
	putBaseAddr = "http://127.0.0.1/put"
)

func main() {
	flag.Parse()

	n := *num
	filename := "payload"

	if *viaNginx == false {
		getBaseAddr = "http://127.0.0.1:8080/get"
		putBaseAddr = "http://127.0.0.1:8080/put"
	}

	log.Printf("putBaseAddr = %v\n", putBaseAddr)
	log.Printf("getBaseAddr = %v\n", getBaseAddr)

	switch *mode {
	case "save_serial":
		bench_save_serial(n, filename)
	case "save_parallel":
		bench_save_parallel(n, 5, filename)
	case "get_serial":
		bench_get_serial(n)
	case "get_parallel":
		bench_get_parallel(n, 5)
	default:
		fmt.Println("valid mode = save_serial, save_parallel, get_serial, get_parallel")
	}
}

func bench_get_parallel(n, gNum int) {
	var length int
	var wg sync.WaitGroup

	log.Printf("getting from tarantool using %v goroutines", gNum)

	t0 := time.Now()

	wg.Add(gNum)
	for i := 0; i < gNum; i++ {
		go func(id int) {
			length = bench_get(n/gNum, id*(n/gNum))
			wg.Done()
		}(i)
	}
	wg.Wait()

	t1 := time.Now()

	log.Printf("size = %v bytes, n = %v, time = %v, speed = %v MB/s\n", length, n, t1.Sub(t0), getSpeed(int64(length), n, t0, t1))
}

func bench_get_serial(n int) {
	t0 := time.Now()

	length := bench_get(n, 1)

	t1 := time.Now()

	log.Printf("size = %v bytes, n = %v, time = %v, speed = %v MB/s\n", length, n, t1.Sub(t0), getSpeed(int64(length), n, t0, t1))
}

func bench_get(n, startID int) int {
	var length int
	var err error
	c := http.Client{}
	for i := 0; i < n; i++ {
		length, err = get(c, fmt.Sprintf("%v", startID+i), getBaseAddr)
		if err != nil {
			log.Fatalf("failed to get id = %v, err = %v", startID+i, err)
		}
	}
	return length
}

func getSpeed(length int64, n int, tStart, tEnd time.Time) float64 {
	return float64(length*int64(n)) / (tEnd.Sub(tStart).Seconds() * 1000000)
}
func get(c http.Client, id, baseAddr string) (int, error) {
	url := fmt.Sprintf("%v/%v", baseAddr, id)
	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return 0, err
	}

	resp, err := c.Do(req)
	if err != nil {
		return 0, err
	}
	defer resp.Body.Close()
	b, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return 0, fmt.Errorf("get data failed err=%v", err)
	}
	return len(b), nil
}

// saving data concurrently using goroutine
func bench_save_parallel(n, gNum int, filename string) {
	log.Printf("Saving to tarantool using %v goroutines", gNum)

	var wg sync.WaitGroup
	t0 := time.Now()

	wg.Add(gNum)
	for i := 0; i < gNum; i++ {
		go func(id int) {
			if err := save(filename, putBaseAddr, n/gNum, id*(n/gNum)); err != nil {
				log.Fatalf("failed to save :%v", err)
			}
			wg.Done()
		}(i)
	}

	wg.Wait()

	t1 := time.Now()
	length := fileSize(filename)
	log.Printf("size = %v bytes, n = %v, time = %v, speed = %v MB/s\n", length, n, t1.Sub(t0), getSpeed(length, n, t0, t1))
}

func bench_save_serial(n int, filename string) {
	log.Printf("Saving to tarantool using 1 goroutine")
	t0 := time.Now()
	if err := save(filename, putBaseAddr, n, 1); err != nil {
		log.Fatalf("failed to save :%v", err)
	}
	t1 := time.Now()

	length := fileSize(filename)
	log.Printf("size = %v bytes, n = %v, time = %v, speed = %v MB/s\n", length, n, t1.Sub(t0), getSpeed(length, n, t0, t1))
}

func fileSize(fileName string) int64 {
	f, err := os.Open(fileName)
	if err != nil {
		log.Fatal(err)
	}
	defer f.Close()
	fi, err := f.Stat()
	if err != nil {
		log.Fatal(err)
	}
	return fi.Size()
}

func save(filename, baseAddr string, n, startID int) error {
	log.Printf("staring save n = %v, start ID = %v", n, startID)
	c := http.Client{}

	// read file
	b, err := ioutil.ReadFile(filename)
	if err != nil {
		return err
	}

	for i := 0; i < n; i++ {
		// create io.Reader
		body := bytes.NewReader(b)
		url := fmt.Sprintf("%v/%v", baseAddr, startID+i)
		req, err := http.NewRequest("POST", url, body)
		if err != nil {
			return err
		}

		resp, err := c.Do(req)
		if err != nil {
			return err
		}
		defer resp.Body.Close()
		if _, err := ioutil.ReadAll(resp.Body); err != nil {
			return fmt.Errorf("saveing failed at n = %v. err=%v", i, err)
		}
	}
	return nil
}
