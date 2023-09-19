# Dicoding Microservices Submission 2: Proyek Deploy Aplikasi Karsa Jobs dengan Kubernetes

## Objective

1. Begin by forking [this repository](https://github.com/dicodingacademy/a433-microservices/), including all its branches, to your GitHub account, and clone the "karsajobs" (backend) and "karsajobs-ui" (frontend) applications from their respective branches. Prepare credential tokens and install necessary software.

2. Create a `build_push_image_karsajobs.sh` script in the backend source code and create `build_push_image_karsajobs_ui.sh` in the frontend source code. Each script should do the following:
   - Build a Docker image from the provided Dockerfile in each source code with the name `<GitHub Packages Container Registry>/<Username>/karsajobs:latest"` (for the backend) and `<GitHub Packages Container Registry>/<Username>/karsajobs-ui:latest` (for the frontend).
   - Login to GitHub Packages.
   - Push the image to GitHub Package.

3. Create a CI pipeline with GitHub Action.
   - Steps required for the "karsajobs" branch:
     - `lint-dockerfile`: Install `hadolint` and run it on the Dockerfile.
     - `test-app`: Run unit tests with the following command: `go test -v -short --count=1 $(go list ./...)`.
     - `build-app-karsajobs`: Build and push the image.
   - Steps required for the `karsajobs-ui` branch:
     - `lint-dockerfile`: Install `hadolint` and run it on Dockerfile.
     - `build-app-karsajobs-ui`: Build and push the image.

4. Deploy the apps on Kubernetes. You should have a folder with Kubernetes manifests that have a structure similar to this:
   ```
   kubernetes
   ├── backend
   │   ├── karsajobs-service.yml
   │   └── karsajobs-deployment.yml
   ├── frontend
   │   ├── karsajobs-ui-service.yml
   │   └── karsajobs-ui-deployment.yml
   └── mongodb
       ├── mongo-configmap.yml
       ├── mongo-secret.yml
       ├── mongo-pv-pvc.yml
       ├── mongo-service.yml
       └── mongo-statefulset.yml
   ```
   - Note for the `karsajobs-deployment.yml`:
     - Fill `VUE_APP_BACKEND` with the value of the Backend Service URL
   - Note for `karsajobs-ui-deployment.yml`:
     - Fill `APP_PORT` env with “8080”.
     - Fill `MONGO_HOST` env from the Service of the MongoDB.
     - Fill `MONGO_USER` env with the value taken from MongoDB Secret (`MONGO_ROOT_USERNAME`).
     - Fill `MONGO_PASS` env with the value from MongoDB Secret (`MONGO_ROOT_PASSWORD`).
   - Note for `mongo-secret.yml`:
     - Fill `MONGO_ROOT_USERNAME` with "admin" in base64 encoded.
     - Fill `MONGO_ROOT_PASSWORD` with "supersecretpassword" in base64 encoded.
   - Note for `mongo-configmap.yml`:
     - Fill the data with the following content:
     ```
     data:
       mongo.conf: |
         storage:
           dbPath: /data/db
     ```
   - Note for `mongo-statefulset.yml`:
     - Environment variable:
       - Fill `MONGO_INITDB_ROOT_USERNAME_FILE` with the value from `/etc/mongo-credentials/MONGO_ROOT_USERNAME`.
       - Fill `MONGO_INITDB_ROOT_PASSWORD_FILE` with the value from `/etc/mongo-credentials/MONGO_ROOT_PASSWORD`.
     - Volume mount:
       - Persistent Volume with a mount path of `/data/db`.
       - ConfigMap with a mount path of `/config`.
       - Secret with a mount path of `/etc/mongo-credentials`.

5. Implement monitoring with Prometheus and Grafana with the following spec:
   - Monitor the Kubernetes Cluster.
   - Deploy both components on a namespace called "monitoring".
   - Use Helm to deploy the component.
   - Use [this dashboard template](https://grafana.com/grafana/dashboards/6417-kubernetes-cluster-prometheus/) to show the Grafana dashboard.

### Solution

### 1. Project Setup

1. Begin by forking the repository to your personal GitHub account. Uncheck the "Copy main branch only" option.

   ![Screenshot 2023-09-12 at 16.33.44.png](_resources/Screenshot%202023-09-12%20at%2016.33.44.png)

2. Clone the "karsajobs" branch from the forked repository.
   ```bash
   git clone https://github.com/<Your GitHub Username>/a433-microservices.git -b karsajobs karsajobs
   ```

3. Clone the "karsajobs-ui" branch from the forked repository.
   ```bash
   git clone https://github.com/<Your GitHub Username>/a433-microservices.git -b karsajobs-ui karsajobs-ui
   ```

4. Create a GitHub personal access token with the "write:packages" access scope for pushing an image to GitHub Packages by following these steps:

   1. Visit the [GitHub Personal Access Tokens](https://github.com/settings/tokens) webpage, and click "Generate new token" -> "Generate new token (classic)" to create a new token.

      ![Screenshot 2023-09-16 at 09.16.28.png](_resources/Screenshot%202023-09-16%20at%2009.16.28.png)

   2. Give the token a name by filling the "Note" field. Then check the "write:packages" access scope to grant the token the necessary permissions (Note: this access scope will also include other dependencies access scopes like "write:repo," etc).

      ![Screenshot 2023-09-16 at 09.23.20.png](_resources/Screenshot%202023-09-16%20at%2009.23.20.png)

   3. Scroll down to the bottom of the webpage and click the "Generate token" button. A newly generated token will appear; save this generated token for later use.

      ![Screenshot 2023-09-16 at 09.25.32.png](_resources/Screenshot%202023-09-16%20at%2009.25.32.png)

5. Add an action secret for the forked repository with the value of the token generated in step 4. Follow these steps:

   1. Go to the forked repository GitHub webpage and navigate to the "Settings" tab.
   2. Scroll down and click the "Secrets and variables" dropdown menu under the "Security" panel, then click "Action."

      ![Screenshot 2023-09-16 at 13.27.00.png](_resources/Screenshot%202023-09-16%20at%2013.27.00.png)

   3. With the "Secrets" tab option selected, click the "New repository secret" button.
   4. After a new webpage appears, fill in the name field with "GH_PACKAGES_TOKEN" and the secret field with the token generated in step 4 that has the "write:packages" permission.

      ![Screenshot 2023-09-16 at 13.32.48.png](_resources/Screenshot%202023-09-16%20at%2013.32.48.png)

   5. Click the "Add secret" button to create the secret.

6. Create a GitHub personal access token with "workflow" access scope for pushing repositories with a workflow used for the GitHub Action CI Pipeline. The steps are similar to those in step 4. After completing the steps, copy the generated token.

7. Adjust the git remote URL of the "karsajobs" repository so that it uses the access token generated in step 6 that has the "workflow" permission.
   ```bash
   cd <Project Root Directory>
   cd karsajobs
   git remote set-url origin https://<Your GitHub Username>:<Your Workflow Token>@github.com/<Your GitHub Username>/a433-microservices.git
   ```

8. Adjust the git remote URL of the "karsajobs-ui" repository so that it uses the access token generated in step 6 that has the "workflow" permission.
   ```bash
   cd <Project Root Directory>
   cd karsajobs-ui
   git remote set-url origin https://<Your GitHub Username>:<Github Workflow Token>@github.com/<Your GitHub Username>/a433-microservices.git
   ```

9. Run a Kubernetes cluster. To run it with Docker Desktop, follow these steps:

   1. Install [Docker Desktop](https://www.docker.com/products/docker-desktop/).
   2. Open Docker Desktop and navigate to the preference panel by clicking the gear icon at the top-right corner, then click the "Kubernetes" option.

      ![Screenshot 2023-09-16 at 14.13.56.png](_resources/Screenshot%202023-09-16%20at%2014.13.56.png)

   3. Check "Enable Kubernetes," then click the "Apply & Restart" button.

10. Create folders for Kubernetes manifests:
    ```bash
	cd <Project Root Directory>
    mkdir kubernetes kubernetes/mongodb kubernetes/frontend kubernetes/backend
    ```

11. Install [Helm](https://helm.sh/docs/intro/install/).

12. Install [kubectl](https://kubernetes.io/docs/tasks/tools/).

### 2. Building and Pushing the karsajobs (backend) image

1. Navigate to the karsajobs project.
   ```bash
   cd <Project Root Directory>
   cd karsajobs
   ```

2. Add the `build_push_image_karsajobs.sh` script to build and push the image.
   ```bash
   nano build_push_image_karsajobs.sh
   ```
   Copy and paste the following content:
   ```bash
   #!/bin/bash

   # Build Docker image
   docker build -t ghcr.io/<Your GitHub Username>/karsajobs:latest .

   # Log in to GitHub Container Registry
   docker login ghcr.io -u <Your GitHub Username> -p $GH_PACKAGES_TOKEN

   # Push Docker image to GitHub Container Registry
   docker push ghcr.io/<Your GitHub Username>/karsajobs:latest
   ```

3. Add a file to specify a workflow that includes steps for implementing the CI pipeline.
   ```bash
   mkdir .github .github/workflows
   nano .github/workflows/config.yml
   ```
   Copy and paste the following content:
   ```yaml
   name: CI for karsajobs  # Descriptive name for your CI workflow

   on:
     push:
       branches:
         - karsajobs  # Trigger the workflow only on pushes to the 'karsajobs' branch

   jobs:
     build:
       runs-on: ubuntu-latest  # Use the latest Ubuntu runner for this job

       steps:
         - name: Checkout Repository  # Checkout the Git repository
           uses: actions/checkout@v2

         - name: Install and Run Hadolint  # Install and run Hadolint to lint Dockerfile
           run: |
             wget -O hadolint https://github.com/hadolint/hadolint/releases/latest/download/hadolint-Linux-x86_64
             chmod +x hadolint
             ./hadolint Dockerfile

         - name: Run Unit Tests  # Run unit tests for the code
           run: go test -v -short --count=1 $(go list ./...)

         - name: Build and Push Docker Image  # Build and push a Docker image
           run: |
             export GH_PACKAGES_TOKEN=${{ secrets.GH_PACKAGES_TOKEN }}
             bash build_push_image_karsajobs.sh
   ```

4. Commit the changes and push.
   ```bash
   git add .
   git commit -m "Adding the build_push_image_karsajobs.sh file to build and push the image"
   git push -u origin karsajobs
   ```

5. Go to the GitHub webpage of the repository and navigate to the "Actions" tab to view the workflow created. You should see the most recent workflow run with a green checkmark indicating a successful execution of the CI Pipeline (if the execution is still running, wait for it to complete).

   ![Screenshot 2023-09-16 at 15.04.57.png](_resources/Screenshot%202023-09-16%20at%2015.04.57.png)

6. Visit the main GitHub dashboard of your account and navigate to the "Packages" tab. You should now see the pushed karsajobs image.

   ![Screenshot 2023-09-16 at 15.07.06.png](_resources/Screenshot%202023-09-16%20at%2015.07.06.png)

7. Adjust the visibility of the karsajobs image to public to fulfill the assignment requirements by following these steps:
   1. Click the name of the image.
   2. Click "Package settings."
   3. Scroll down to the "Danger Zone" panel and click the "Change visibility" button.
   4. Select "public" under the "Change visibility" popup. Then type the name of the image in the provided field and click the "I understand the consequences, change package visibility" button.

   The "private" label beside the image name should now be hidden.

### 3. Building and Pushing karsajobs-ui (frontend) image

1. Navigate to the karsajobs-ui folder.
   ```bash
   cd <Project Root Directory>
   cd karsajobs-ui
   ```

2. Add the `build_push_image_karsajobs_ui.sh` script to build and push the image.
   ```bash
   nano build_push_image_karsajobs_ui.sh
   ```
   Copy and paste the following content:
   ```bash
   #!/bin/bash

   # Build Docker image
   docker build -t ghcr.io/<Your GitHub Username>/karsajobs-ui:latest .

   # Log in to GitHub Container Registry
   docker login ghcr.io -u <Your GitHub Username> -p $GH_PACKAGES_TOKEN

   # Push Docker image to GitHub Container Registry
   docker push ghcr.io/<Your GitHub Username>/karsajobs-ui:latest
   ```

3. Add a file to specify a workflow that includes steps to be executed as part of the CI pipeline.
   ```bash
   mkdir .github .github/workflows
   nano .github/workflows/config.yml
   ```

   Copy and paste the following content:
   ```yaml
   name: CI for karsajobs-ui  # Define a descriptive name for this GitHub Actions workflow

   on:
     push:
       branches:
         - karsajobs-ui  # Trigger this workflow on pushes to the 'karsajobs-ui' branch

   jobs:
     build:
       runs-on: ubuntu-latest  # Specify the operating system for this job

       steps:
         - name: Checkout Repository  # Step to checkout the repository
           uses: actions/checkout@v2

         - name: Install and Run Hadolint  # Step to install Hadolint and run it on Dockerfile
           run: |
             wget -O hadolint https://github.com/hadolint/hadolint/releases/latest/download/hadolint-Linux-x86_64
             chmod +x hadolint
             ./hadolint Dockerfile

         - name: Build and Push Docker Image  # Step to build and push a Docker image
           run: |
             export GH_PACKAGES_TOKEN=${{ secrets.GH_PACKAGES_TOKEN }}
             bash build_push_image_karsajobs_ui.sh
   ```

4. Commit the changes and push.
   ```bash
   git add .
   git commit -m "Adding the build_push_image_karsajobs_ui.sh file to build and push the image"
   git push -u origin karsajobs-ui
   ```

5. Go to the GitHub webpage of the repository and navigate to the "Actions" tab to view the workflow created. You should see the most recent workflow run with a green checkmark indicating a successful execution of the CI Pipeline (if the execution is still running, wait for it to complete).

   ![Screenshot 2023-09-16 at 15.20.25.png](_resources/Screenshot%202023-09-16%20at%2015.20.25.png)

6. Go to the main GitHub dashboard of your account and navigate to the "Packages" tab. You should now see the pushed karsajobs-ui image.

   ![Screenshot 2023-09-16 at 15.21.13.png](_resources/Screenshot%202023-09-16%20at%2015.21.13.png)

7. Adjust the visibility of the karsajobs-ui image to public to fulfill the assignment requirements by following these steps:
   1. Click the name of the image.
   2. Click "Package settings."
   3. Scroll down to the "Danger Zone" panel and click the "Change visibility" button.
   4. Select "public" under the "Change visibility" popup. Then type the name of the image in the provided field and click the "I understand the consequences, change package visibility" button.

   The "private" label beside the image name should now be hidden.

### 4. Deploying MongoDB on Kubernetes

1. Navigate to the MongoDB manifest folder.
   ```bash
   cd <Project Root Directory>
   cd kubernetes/mongodb
   ```

2. Create a Kubernetes manifest script for the ConfigMap.
   ```bash
   nano mongo-configmap.yml
   ```
   Copy and paste the following content:
   ```yaml
	apiVersion: v1  # Specifies the Kubernetes API version being used.
	kind: ConfigMap  # Defines the type of Kubernetes resource being created, which is a ConfigMap in this case.

	metadata:
	  name: mongo-configmap  # Specifies the name of the ConfigMap being created.
	  labels:
	    app: mongo  # Defines a label for the ConfigMap, associating it with the "mongo" application.

	data:
	  mongo.conf: |  # Configures the MongoDB storage settings, specifying the database path.
	    storage:
	      dbPath: /data/db 

   ```

3. Create a Kubernetes manifest script for the PersistentVolume and PersistentVolumeClaim.
   ```bash
   nano mongo-pv-pvc.yml
   ```
   Copy and paste the following content:
   ```yaml
	apiVersion: v1 # Specifies the Kubernetes API version being used.
	kind: PersistentVolume  # Defines the Kubernetes resource type as a Persistent Volume
	metadata:
	  name: mongo-pv  # Name of the PersistentVolume
	  labels:
	    type: local  # Label to identify the type as local
	spec:
	  storageClassName: manual  # Storage class for the PersistentVolume
	  capacity:
	    storage: 1Gi  # Storage capacity of the PersistentVolume
	  accessModes:
	    - ReadWriteOnce  # Access mode for the PersistentVolume
	  hostPath:
	    path: "/mnt/data/db"  # Host path for the PersistentVolume

	---

	apiVersion: v1 # Specifies the Kubernetes API version being used.
	kind: PersistentVolumeClaim # Defines the Kubernetes resource type as a Persistent Volume Claim
	metadata:
	  name: mongo-pvc  # Name of the PersistentVolumeClaim
	  labels:
	    app: mongo  # Label to identify the application as mongo
	spec:
	  storageClassName: manual  # Storage class for the PersistentVolumeClaim
	  accessModes:
	    - ReadWriteOnce  # Access mode for the PersistentVolumeClaim
	  resources:
	    requests:
	      storage: 1Gi  # Requested storage capacity for the PersistentVolumeClaim

   ```

4. Create a Kubernetes manifest script for the Secret.
   ```bash
   nano mongo-secret.yml
   ```
   Copy and paste the following content:
   ```yaml
	apiVersion: v1  # Specifies the Kubernetes API version being used.
	kind: Secret  # Defines that this is a Kubernetes Secret resource.
	metadata:
	  name: mongo-secret  # Specifies the name of the Secret resource.
	  labels:
	    app: mongo  # Assigns the 'mongo' label to this Secret resource.

	data:
	  MONGO_ROOT_PASSWORD: c3VwZXJzZWNyZXRwYXNzd29yZA==  # Base64 encoded value of the MongoDB root password.
	  MONGO_ROOT_USERNAME: YWRtaW4=  # Base64 encoded value of the MongoDB root username.
   ```

5. Create a Kubernetes manifest script for the Service.
   ```bash
   nano mongo-service.yml
   ```
   Copy and paste the following content:
   ```yaml
	apiVersion: v1 # Specifies the Kubernetes API version being used
	kind: Service # Defines the Kubernetes resource type as a Service
	metadata:
	  name: mongo-svc # Sets the name of the Service as 'mongo-svc'
	  labels:
	    app: mongo # Labels the Service with 'app: mongo' for identification
	spec:
	  ports:
	    - port: 27017 # Specifies the port to be exposed (27017 in this case)
	  selector:
	    tier: data # Defines the selector for identifying Pods to route traffic to
	  clusterIP: None # Specifies 'None' for the clusterIP to indicate headless service

   ```

6. Create a Kubernetes manifest script for the StatefulSet.
   ```bash
   nano mongo-statefulset.yml
   ```
   Copy and paste the following content:
   ```yaml
	apiVersion: apps/v1  # Specifies the Kubernetes API version for the resource
	kind: StatefulSet  # Defines the Kubernetes resource type as a StatefulSet

	metadata:
	  name: mongo-statefulset  # Specifies the name for this StatefulSet
	  labels:
	    app: mongo  # Labels to identify this StatefulSet
	spec:
	  serviceName: mongo-svc  # Specifies the service name associated with this StatefulSet
	  replicas: 1  # Defines the desired number of replicas for the StatefulSet
	  selector:
	    matchLabels:
	      app: mongo  # Labels used to match Pods controlled by this StatefulSet
	      tier: data  # Additional label used to match Pods controlled by this StatefulSet
	  minReadySeconds: 10  # Defines the minimum number of seconds for a Pod to be considered ready
	  template:
	    metadata:
	      labels:
	        app: mongo  # Labels for Pods created from this template
	        tier: data  # Additional label for Pods created from this template
	    spec:
	      terminationGracePeriodSeconds: 10  # Defines the termination grace period for Pod shutdown
	      containers:
	      - name: mongo  # Name of the container within the Pod
	        image: mongo:latest  # Specifies the Docker image to use for the container
	        ports:
	        - containerPort: 27017  # Defines the container port to expose
	        env:
	        - name: MONGO_INITDB_ROOT_USERNAME_FILE  # Environment variable for MongoDB root username file
	          value: "/etc/mongo-credentials/MONGO_ROOT_USERNAME"  # Value for the environment variable
	        - name: MONGO_INITDB_ROOT_PASSWORD_FILE  # Environment variable for MongoDB root password file
	          value: "/etc/mongo-credentials/MONGO_ROOT_PASSWORD"  # Value for the environment variable
	        volumeMounts:
	        - name: data-volume  # Name of the volume to mount
	          mountPath: /data/db  # Mount path within the container
	        - name: config-volume  # Name of the volume to mount
	          mountPath: /config  # Mount path within the container
	        - name: secret-volume  # Name of the volume to mount
	          mountPath: /etc/mongo-credentials  # Mount path within the container
	      volumes:
	      - name: data-volume  # Name of the volume
	        persistentVolumeClaim:
	          claimName: mongo-pvc  # Name of the PersistentVolumeClaim to use for the volume
	      - name: config-volume  # Name of the volume
	        configMap:
	          name: mongo-configmap  # Name of the ConfigMap to use for the volume
	      - name: secret-volume  # Name of the volume
	        secret:
	          secretName: mongo-secret  # Name of the Secret to use for the volume

   ```

7. Deploy all the MongoDB objects to the Kubernetes cluster.
   ```bash
   kubectl apply -f .
   ```

8. Confirm that the MongoDB pod is running.
   ```bash
   kubectl get pods -l app=mongo
   ```

   ![Screenshot 2023-09-16 at 16.21.12.png](_resources/Screenshot%202023-09-16%20at%2016.21.12.png)
 
### 5. Deploying the Backend on Kubernetes

1. Navigate to the backend folder.
   ```bash
   cd <Project Root Directory>
   cd kubernetes/backend
   ```

2. Create a Kubernetes manifest file for the backend deployment.
   ```bash
   nano karsajobs-deployment.yml
   ```
   Copy and paste the following content:
   ```yaml
	apiVersion: apps/v1 # Specifies the Kubernetes API version being used.
	kind: Deployment  # Defines the Kubernetes resource type as a Deployment
	metadata:
	  name: karsajobs-deploy  # Name of the deployment
	  labels:
	    app: karsajobs  # Label for identifying the app
	spec:
	  replicas: 1  # Number of replica pods to maintain
	  selector:
	    matchLabels:
	      app: karsajobs  # Selector for identifying the app
	      tier: backend  # Selector for identifying the tier
	  template:
	    metadata:
	      labels:
	        app: karsajobs  # Label for identifying the app
	        tier: backend  # Label for identifying the tier
	    spec:
	      containers:
	      - name: karsajobs  # Container name
	        image: ghcr.io/<Your GitHub Username>/karsajobs:latest  # Docker image location
	        ports:
	        - containerPort: 8080  # Port to expose in the container
	        env:
	        - name: APP_PORT  # Environment variable for the app port
	          value: "8080"  # Value for the app port
	        - name: MONGO_HOST  # Environment variable for MongoDB host
	          value: mongo-svc  # Value for the MongoDB host
	        - name: MONGO_USER  # Environment variable for MongoDB username
	          valueFrom:
	            secretKeyRef:
	              name: mongo-secret  # Name of the secret containing MongoDB credentials
	              key: MONGO_ROOT_USERNAME  # Key in the secret for MongoDB username
	        - name: MONGO_PASS  # Environment variable for MongoDB password
	          valueFrom:
	            secretKeyRef:
	              name: mongo-secret  # Name of the secret containing MongoDB credentials
	              key: MONGO_ROOT_PASSWORD  # Key in the secret for MongoDB password
   ```

3. Create a manifest file for the backend service:
   ```bash
   nano karsajobs-service.yml
   ```
   Copy and paste the following content:
   ```yaml
	apiVersion: v1 # Specifies the Kubernetes API version being used.
	kind: Service  # Defines the Kubernetes resource type as a Service
	metadata:
	  name: karsajobs-svc  # Name of the service
	  labels:
	    app: karsajobs  # Labeling the service for categorization
	spec:
	  type: NodePort  # Service type: exposed externally through a node port
	  selector:
	    tier: backend  # Selecting pods based on the 'tier' label being 'backend'
	  ports:
	  - port: 8080  # Port on which the service is listening internally
	    name: karsajobs  # Name of the port
	    protocol: TCP  # Protocol used (TCP in this case)
	    nodePort: 30007  # Node port exposed externally for accessing the service

   ```

4. Deploy all the backend objects to the Kubernetes cluster.
   ```bash
   kubectl apply -f .
   ```

5. After a backend pod is running, confirm that the backend is connected to the MongoDB correctly by visiting its `/jobs` endpoint. (Note: the Kubernetes cluster provided by Docker Desktop automatically exposes the node port to the host, so you can use localhost in this case. Alternatively, you may need to replace localhost with your node IP address.)
   ```bash
   curl localhost:30007/jobs
   ```
   ![Screenshot 2023-09-16 at 16.35.43.png](_resources/Screenshot%202023-09-16%20at%2016.35.43.png)

   The result of null in this case indicates that the backend is successfully connected to the MongoDB, even though there is no data.

### 6. Deploying the Frontend on Kubernetes

1. Navigate to the frontend folder.
   ```bash
   cd <Project Root Directory>
   cd kubernetes/frontend
   ```

2. Create a Kubernetes manifest file for the frontend deployment.
   ```bash
   nano karsajobs-ui-deployment.yml
   ```
   Copy and paste the following content:
   ```yaml
	apiVersion: apps/v1 # Specifies the Kubernetes API version being used.
	kind: Deployment  # Defines the Kubernetes resource type as a Deployment
	metadata:
	  name: karsajobs-ui-deploy # Name of the Deployment
	  labels:
	    app: karsajobs-ui # Label for the app
	spec:
	  replicas: 1 # Number of desired replicas for the application
	  selector:
	    matchLabels:
	      app: karsajobs-ui # Selector label for the app
	      tier: frontend # Selector label for the tier (frontend in this case)
	  template:
	    metadata:
	      labels:
	        app: karsajobs-ui # Label for the app within the pod
	        tier: frontend # Label for the tier within the pod
	    spec:
	      containers:
	      - name: karsajobs-ui # Name of the container
	        image: ghcr.io/<Your GitHub Username>/karsajobs-ui:latest # Docker image used for the container
	        ports:
	        - containerPort: 8000 # Port to expose within the container
	        env:
	        - name: VUE_APP_BACKEND
	          value: "http://localhost:30007" # Environment variable for the backend URL

   ```
3. Create a Kubernetes manifest file for the frontend deployment.
	```bash
	nano karsajobs-ui-service.yml
	```

	Copy and paste the following content:
	```yaml
	apiVersion: v1  # Specifies the Kubernetes API version being used (v1 in this case).
	kind: Service    # Specifies the type of Kubernetes resource being defined (Service in this case).
	metadata:
	  name: karsajobs-ui-svc  # Name of the service being created.
	  labels:
	    app: karsajobs-ui   # Label for the application being associated with this service.
	spec:
	  type: NodePort  # Specifies the type of service as NodePort (accessible externally via a port on each node).
	  selector:
	    tier: frontend  # Selects the pods to include in this service based on the specified label.
	  ports:
	  - port: 8000   # Specifies the port on which the service will listen within the cluster.
	    name: karsajobs-ui   # Name for the port being used by the service.
	    protocol: TCP   # Specifies the protocol being used (TCP in this case).
	    nodePort: 30008   # Specifies the port on the node that will be forwarded to the service's port.

	```

4. Deploy all the frontend objects to the Kubernetes cluster.
   ```bash
   kubectl apply -f .
   ```

5. Confirm the frontend pod is running:

   ![Screenshot 2023-09-16 at 16.52.50.png](_resources/Screenshot%202023-09-16%20at%2016.52.50.png)

   Visit `localhost:30008` in the browser (replace localhost with your node IP if needed). You should see the webpage provided by the frontend app.

   ![Screenshot 2023-09-16 at 16.51.39.png](_resources/Screenshot%202023-09-16%20at%2016.51.39.png)

   Go to the Manage Jobs panel by clicking the button at the top right corner. Submit new job items to test the frontend integration with the backend. After populating some data, you should see the homepage populated by the data.

   ![Screenshot 2023-09-16 at 16.59.18.png](_resources/Screenshot%202023-09-16%20at%2016.59.18.png)

### 7. Deploying Prometheus and Grafana

1. Create a Namespace for Monitoring:
   ```bash
   kubectl create namespace monitoring
   ```

2. Add Helm Repositories for Grafana and Prometheus:
   ```bash
   helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
   helm repo add grafana https://grafana.github.io/helm-charts
   helm repo update
   ```

3. Deploy Prometheus on Kubernetes:
   ```bash
   helm install prometheus prometheus-community/prometheus --namespace monitoring
   ```

4. Deploy Grafana on Kubernetes:
   ```bash
   helm install grafana grafana/grafana --namespace monitoring
   ```

5. Confirm that all Prometheus and Grafana pods are running:
   ```bash
   kubectl get pods -n monitoring
   ```

   ![Screenshot 2023-09-16 at 17.18.57.png](_resources/Screenshot%202023-09-16%20at%2017.18.57.png)

   (OPTIONAL) If you encounter an error related to mountPropagation in prometheus-prometheus-node-exporter daemonset pods, adjust the mountPropagation to use the default:
   ```bash
   kubectl patch ds prometheus-prometheus-node-exporter -n monitoring --type "json" -p '[{"op": "remove", "path" : "/spec/template/spec/containers/0/volumeMounts/2/mountPropagation"}]'
   ```

### 8. Creating the Cluster Dashboard on Grafana

1. Make Grafana accessible on the host at "localhost:3000":
   ```bash
   kubectl port-forward svc/grafana -n monitoring 3000:80
   ```

2. Visit Grafana in your browser. You should see Grafana login page.

   ![Screenshot 2023-09-16 at 17.29.14.png](_resources/Screenshot%202023-09-16%20at%2017.29.14.png)

3. Use "admin" as the `username` and execute the following code to obtain the `password`:
   ```bash
   kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
   ```

4. Click the "Log in" button. You should now enter to the Grafana main webpage.

   ![Screenshot 2023-09-16 at 17.39.55.png](_resources/Screenshot%202023-09-16%20at%2017.39.55.png)

5. Add a data source from the Prometheus server by following these steps:
   1. Go to the main Grafana webpage.
   2. Click on the "Data Source" card.
   3. Select Prometheus under Time series database as the data source type.
   4. Fill the "Prometheus server URL" field with "http://prometheus-server:80".
   5. Scroll down and click the "Save & Test" button.

      ![Screenshot 2023-09-16 at 17.45.01.png](_resources/Screenshot%202023-09-16%20at%2017.45.01.png)

6. Add a dashboard by following these steps:
   1. Click the menu button at the top left corner and select "Dashboards".

      ![Screenshot 2023-09-16 at 17.56.25.png](_resources/Screenshot%202023-09-16%20at%2017.56.25.png)

   2. Click "Import" under the "New" drop-down menu.

      ![Screenshot 2023-09-16 at 17.58.55.png](_resources/Screenshot%202023-09-16%20at%2017.58.55.png)

   3. Enter "6417" into the "Import via grafana.com" field to specify the dashboard theme. Then click the load button beside the field.

   4. Select the previously created data source, in this case called "Prometheus". Then click Import. You should now see the dashboard similar to the following:

      ![Screenshot 2023-09-16 at 18.13.25.png](_resources/Screenshot%202023-09-16%20at%2018.13.25.png)

   5. Click "Save dashboard" beside the blue "Add" dropdown button to open up a panel to save the dashboard. Then click "Save" on the panel to save.