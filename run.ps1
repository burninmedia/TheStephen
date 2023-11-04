param(
    [Parameter(Position=0, Mandatory=$true)][string]$command,
    [Parameter(Position=1)][string]$subCommand,
    [Parameter(Position=2)][string]$thirdParam
)

# Define the Docker image and container names
$imageName = "autogpt-app"
$containerName = "autogpt-container"

# Define the port mapping (host:container)
$hostPort = "8080"
$containerPort = "8000"

# Function to check if Docker is running
function Check-DockerRunning {
    try {
        docker info > $null
        return $true
    } catch {
        Write-Host "Docker does not appear to be running. Please start Docker and try again." -ForegroundColor Red
        return $false
    }
}

# Function to check if the Docker image exists
function Image-Exists {
    $existingImages = docker images -q $imageName
    return $existingImages -ne $null
}

# Function to build the Docker image if it doesn't exist
function Build-ImageIfNeeded {
    if (-not (Image-Exists)) {
        docker build -t $imageName .
    }
}

# Function to restart the docker container
function Restart-Container {
    $containerRunning = docker ps -q -f name=$containerName
    if ($containerRunning) {
        docker stop $containerName
        docker rm $containerName
    }
    docker run --name $containerName -d -p "${hostPort}:${containerPort}" $imageName
}

# Function to ensure the container is running
function Ensure-ContainerRunning {
    $containerRunning = docker ps -q -f name=$containerName
    if (-not $containerRunning) {
        docker run --name $containerName -d -p "${hostPort}:${containerPort}" $imageName
    }
}

# Function to send a command to the running Docker container
function Send-CommandToContainer {
    param(
        [string]$dockerCommand
    )
    Write-Host "Sending command: docker exec $containerName /bin/bash -c 'python3 ./cli.py $dockerCommand'"
    $output = docker exec $containerName /bin/bash -c "python3 ./cli.py $dockerCommand"
    Write-Output $output
}

# Check if Docker is running before proceeding
if (-not (Check-DockerRunning)) {
    return
}

if ($command -eq "setup") {
    Build-ImageIfNeeded
    Ensure-ContainerRunning
    # Call the setup command on cli.py
    Send-CommandToContainer -dockerCommand "setup"
} elseif ($command -eq "build") {
    docker build -t $imageName .
} else {
    Ensure-ContainerRunning
    # Join all arguments with space as a separator and pass them to the Docker container
    $dockerCommand = $args -join " "
    Send-CommandToContainer -dockerCommand $dockerCommand
}