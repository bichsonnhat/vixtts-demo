#!/usr/bin/env bash

PYTHON_VERSION=3.10

# Function to parse arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --audio)
                audio_path="$2"
                shift 2
                ;;
            --text)
                text="$2"
                shift 2
                ;;
            --output)
                output_path="$2"
                shift 2
                ;;
            *)
                echo "Unknown argument: $1"
                exit 1
                ;;
        esac
    done
}

# Call the function to parse arguments
parse_arguments "$@"  

# Now you can use the variables $audio_path, $text, and $output_path

echo "Received audio path: $audio_path"
echo "Received text: $text"
echo "Output path: $output_path"

# Check for required dependencies
dependencies=("python${PYTHON_VERSION}" "python${PYTHON_VERSION}-venv" "python${PYTHON_VERSION}-dev")
missing_dependencies=()

for dep in "${dependencies[@]}"; do
    if ! dpkg -s "$dep" &> /dev/null; then
        missing_dependencies+=("$dep")
    fi
done

if [ ${#missing_dependencies[@]} -gt 0 ]; then
    echo "Missing dependencies: ${missing_dependencies[*]}"
    echo "Please install them using 'sudo apt install ${missing_dependencies[*]}'"
    exit 1
fi

if python$PYTHON_VERSION --version &> /dev/null; then
    echo "Using Python version: $PYTHON_VERSION"
    if [ -f .env/ok ]; then
        source .env/bin/activate
    else
        echo "The environment is not ok. Running setup..."
        rm -rf .env
        python$PYTHON_VERSION -m venv .env && \
        source .env/bin/activate && \
        git submodule update --init --recursive && \
        cd TTS && \
        git fetch --tags && \
        git checkout 0.1.1 && \
        echo "Installing TTS..." && \
        pip install --use-deprecated=legacy-resolver -e . -q && \
        cd .. && \
        echo "Installing other requirements..." && \
        pip install -r requirements.txt -q && \
        echo "Downloading Japanese/Chinese tokenizer..." && \
        python -m unidic download
        touch .env/ok
    fi
    python vixtts_demo.py --audio "$audio_path" --text "$text" --output "$output_path" 
else
    echo "Python version $PYTHON_VERSION is not installed. Please install it."
fi