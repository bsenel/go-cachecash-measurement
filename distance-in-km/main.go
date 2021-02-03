package main

import (
	"context"
	"flag"
	"log"
	"math"
	"os"
	"path/filepath"
	"strconv"

	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/tools/clientcmd"
)

func main() {
	cacheNodeName := flag.String("cache", "edgenet.planet-lab.eu", "the node that runs caches")
	flag.Parse()

	clientset, err := createClientSet()
	if err != nil {
		log.Println(err.Error())
		panic(err.Error())
	}

	var lonA float64
	var latA float64
	var lonB float64
	var latB float64
	cacheNode, err := clientset.CoreV1().Nodes().Get(context.TODO(), string(*cacheNodeName), metav1.GetOptions{})
	if err != nil {
		log.Println(err.Error())
		panic(err.Error())
	}
	if cacheNode.Labels["edge-net.io/lon"] != "" && cacheNode.Labels["edge-net.io/lat"] != "" {
		// Because of alphanumeric limitations of Kubernetes on the labels we use "w", "e", "n", and "s" prefixes
		// at the labels of latitude and longitude. Here is the place those prefixes are dropped away.
		lonStr := cacheNode.Labels["edge-net.io/lon"]
		lonStr = string(lonStr[1:])
		latStr := cacheNode.Labels["edge-net.io/lat"]
		latStr = string(latStr[1:])
		if lon, err := strconv.ParseFloat(lonStr, 64); err == nil {
			if lat, err := strconv.ParseFloat(latStr, 64); err == nil {
				lonB = lon * math.Pi / 180
				latB = lat * math.Pi / 180
			}
		}
	}

	nodesRaw, err := clientset.CoreV1().Nodes().List(context.TODO(), metav1.ListOptions{})
	if err != nil {
		log.Println(err.Error())
		panic(err.Error())
	}
	for _, nodeRow := range nodesRaw.Items {
		if nodeRow.Labels["edge-net.io/lon"] != "" && nodeRow.Labels["edge-net.io/lat"] != "" {
			// Because of alphanumeric limitations of Kubernetes on the labels we use "w", "e", "n", and "s" prefixes
			// at the labels of latitude and longitude. Here is the place those prefixes are dropped away.
			lonStr := nodeRow.Labels["edge-net.io/lon"]
			lonStr = string(lonStr[1:])
			latStr := nodeRow.Labels["edge-net.io/lat"]
			latStr = string(latStr[1:])
			if lon, err := strconv.ParseFloat(lonStr, 64); err == nil {
				if lat, err := strconv.ParseFloat(latStr, 64); err == nil {
					log.Printf("Distance from %s to %s", nodeRow.Labels["kubernetes.io/hostname"], string(*cacheNodeName))
					lonA = lon * math.Pi / 180
					latA = lat * math.Pi / 180
					distanceByHaversine(lonA, latA, lonB, latB)
				}
			}
		}
	}
}

func homeDir() string {
	if h := os.Getenv("HOME"); h != "" {
		return h
	}
	return os.Getenv("USERPROFILE")
}

func createClientSet() (*kubernetes.Clientset, error) {
	var path string
	if home := homeDir(); home != "" {
		path = filepath.Join(home, ".kube", "config")
	} else {
		path = "./"
	}
	config, err := clientcmd.BuildConfigFromFlags("", path)
	if err != nil {
		log.Println(err.Error())
		panic(err.Error())
	}
	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		log.Println(err.Error())
		panic(err.Error())
	}
	return clientset, err
}

func distanceByHaversine(lonA, latA, lonB, latB float64) float64 {
	distance := 2 * 6371 * math.Asin(math.Sqrt(math.Pow(math.Sin((latB-latA)/2), 2)+math.Cos(latA)*math.Cos(latB)*math.Pow(math.Sin((lonB-lonA)/2), 2)))
	//log.Printf("From (%f,%f) to (%f,%f)): %f km", lonA, latA, lonB, latB, distance)
	log.Printf("%f km", distance)
	return distance
}
