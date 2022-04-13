package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
)

var workingdir string
var zokrates_base_path string

func addCORS(w http.ResponseWriter, methods string) {
	//headers to keep firefox happy
	headers := w.Header()
	headers.Add("Access-Control-Allow-Origin", "*")
	headers.Add("Access-Control-Allow-Headers", "Content-Type, Origin, Accept, token")
	headers.Add("Access-Control-Allow-Credentials", "true")
	headers.Add("Access-Control-Allow-Methods", methods)
	headers.Add("Vary", "Origin")
	headers.Add("Vary", "Access-Control-Request-Method")
	headers.Add("Vary", "Access-Control-Request-Headers")
}

func compute_hash(secret_number string) (hash string) {
	compute_hash_file := filepath.Join(zokrates_base_path, "compute_hash.bat")
	cmd := exec.Command(compute_hash_file, secret_number)
	cmd.Run()

	compute_hash_witness_file := filepath.Join(zokrates_base_path, "compute_hash", "compute_hash_witness")
	compute_hash_witness_fs, err_file := os.Open(compute_hash_witness_file)
	defer compute_hash_witness_fs.Close()
	if err_file != nil {
		log.Panic(err_file)
		return
	}

	// scan 1st line for the hash
	var ret_hash string
	scanner := bufio.NewScanner(compute_hash_witness_fs)
	for scanner.Scan() {
		n, err := fmt.Sscanf(scanner.Text(), "~out_0 %s", &ret_hash)
		if err != nil {
			log.Panic(n)
			log.Panic(err)
			//response.WriteHeader(http.StatusInternalServerError)
			return
		}
		break
	}
	return ret_hash
}

func InitiateGameHandler(response http.ResponseWriter, req *http.Request) {
	// log.Print("--------")
	// log.Print(req.Method)
	// log.Print(req.Body)
	// log.Print("--------")
	if req.Method == "OPTIONS" {
		// log.Print("preflight detected: ", req.Header)
		addCORS(response, "POST,OPTIONS")
		response.WriteHeader(http.StatusOK)
		return
	} else if req.Method != "POST" {
		response.WriteHeader(http.StatusBadRequest)
		return
	}
	headers := response.Header()
	headers.Add("Access-Control-Allow-Origin", "*")

	buffer, err := ioutil.ReadAll((req.Body))
	if err != nil {
		log.Panic(err)
		response.WriteHeader(http.StatusInternalServerError)
		response.Write([]byte("500 - Something bad happened!"))
		return
	}
	req.Body.Close()

	var payload interface{}
	json.Unmarshal(buffer, &payload)

	// conversion to array
	m := payload.([]interface{})
	//m := (map[string]interface{}) //conversion to key-value pair
	log.Print("wtf")
	log.Print(m)

	if len(m) != 3 {
		response.WriteHeader(http.StatusInternalServerError)
		response.Write([]byte("Wrong number of arguments!"))
		return
	}
	secret_number := fmt.Sprintf("%s", m[0])
	lower_range := fmt.Sprintf("%s", m[1])
	upper_range := fmt.Sprintf("%s", m[2])

	hash := compute_hash(secret_number)

	// run initiate_game.bat and obtain proof.json, then call the transaction
	compute_proof_file := filepath.Join(zokrates_base_path, "initiate_game.bat")
	initiate_game_cmd := exec.Command(compute_proof_file, "initiate_game", secret_number, hash, lower_range, upper_range)
	var cmd_err = initiate_game_cmd.Run()
	if cmd_err != nil {
		log.Print(cmd_err.Error())
		response.WriteHeader(http.StatusInternalServerError)
		response.Write([]byte("initiate_game ran into an error!"))
		return
	}

	proof_file := filepath.Join(zokrates_base_path, "initiate_game", "proof.json")
	proof_bytes, file_err := ioutil.ReadFile(proof_file)
	if file_err != nil {
		log.Panic(file_err)
		response.WriteHeader(http.StatusInternalServerError)
		return
	}

	response.Header().Set("Content-Type", "application/json")
	response.Write(proof_bytes)
}

func EvalGuessHandler(response http.ResponseWriter, req *http.Request) {
	if req.Method == "OPTIONS" {
		// log.Print("preflight detected: ", req.Header)
		addCORS(response, "POST,OPTIONS")
		response.WriteHeader(http.StatusOK)
		return
	} else if req.Method != "POST" {
		response.WriteHeader(http.StatusBadRequest)
		return
	}
	headers := response.Header()
	headers.Add("Access-Control-Allow-Origin", "*")

	buffer, err := ioutil.ReadAll((req.Body))
	if err != nil {
		log.Panic(err)
		response.WriteHeader(http.StatusInternalServerError)
		response.Write([]byte("500 - Something bad happened!"))
		return
	}
	req.Body.Close()

	var payload interface{}
	json.Unmarshal(buffer, &payload)
	// conversion to array
	m := payload.([]interface{})
	log.Print(m)

	if len(m) != 2 {
		response.WriteHeader(http.StatusInternalServerError)
		response.Write([]byte("Wrong number of arguments!"))
		return
	}

	secret_number := fmt.Sprintf("%s", m[0])
	guess := fmt.Sprintf("%s", m[1])

	hash := compute_hash(secret_number)

	// run compute_proof.bat and obtain proof.json, then call the transaction
	compute_proof_file := filepath.Join(zokrates_base_path, "eval_guess.bat")
	eval_guess_cmd := exec.Command(compute_proof_file, "eval_guess", secret_number, hash, guess)
	var cmd_err = eval_guess_cmd.Run()
	if cmd_err != nil {
		log.Print(cmd_err.Error())
		response.WriteHeader(http.StatusInternalServerError)
		response.Write([]byte("eval_guess ran into an error!"))
		return
	}

	proof_file := filepath.Join(zokrates_base_path, "eval_guess", "proof.json")
	proof_bytes, file_err := ioutil.ReadFile(proof_file)
	if file_err != nil {
		log.Panic(file_err)
		response.WriteHeader(http.StatusInternalServerError)
		return
	}

	response.Header().Set("Content-Type", "application/json")
	response.Write(proof_bytes)
}

func GameLayerAbiHandler(response http.ResponseWriter, req *http.Request) {
	if req.Method == "OPTIONS" {
		// log.Print("preflight detected: ", req.Header)
		addCORS(response, "GET,OPTIONS")
		response.WriteHeader(http.StatusOK)
		return
	} else if req.Method != "GET" {
		response.WriteHeader(http.StatusBadRequest)
		return
	}
	headers := response.Header()
	headers.Add("Access-Control-Allow-Origin", "*")

	contract_abi_file := filepath.Join(workingdir, "..", "build", "contracts", "GuessTheNumberGameLayer.json")
	proof_bytes, file_err := ioutil.ReadFile(contract_abi_file)
	if file_err != nil {
		log.Panic(file_err)
		response.WriteHeader(http.StatusInternalServerError)
		return
	}

	response.Header().Set("Content-Type", "application/json")
	response.Write(proof_bytes)
}

func main() {
	log.Printf("Starting server..")

	workingdir, wd_err := os.Getwd()
	if wd_err != nil {
		log.Print(wd_err)
		return
	}
	zokrates_base_path := filepath.Join(workingdir, "..", "zokrates")
	os.Chdir(zokrates_base_path)

	http.HandleFunc("/initiate_game", InitiateGameHandler)
	http.HandleFunc("/eval_guess", EvalGuessHandler)

	http.HandleFunc("/game_layer_abi", GameLayerAbiHandler)

	http.ListenAndServe("127.0.0.1:3000", nil)
}
