# Automatic builds of new releases of NVIDIA drivers with Konflux



* **releases.json** file with the same format as the one NVIDIA publishes but shortened (for testing purposes now)
* **kernel_versions.json** that has the results of retrieving the available tags of the DTK DCI releases. Each tag is a different kernel version.
* **create_matrix.sh** script file that would create the _matrix_ JSON in a file called **drivers_matrix.json** from above data and a **drivers_matrix.MD5SUM **that will serve as a control file when checking changes. The script will also check if a specific version exists in the specified image registry and will set the _published_ field accordingly at the output matrix.
* A script called **update_dockerfile.sh** that will check the matrix for non published, but available versions and will update the **Dockerfile** at the root level of the repository with the specific kernel/drivers version to be built. Later it will change the _pipelineRun_ at the **.tekton **directory to change  the version of the image that will be uploaded to the set registry after triggering the Konflux build.

 

The triggering mechanism is defined at a Github action where a periodic task will run the above **create_matrix.sh **script** **at defined intervals. If the script finds changes in the source _JSON_ files it will change the resulting matrix, adding a new entry to it and thus changing the _MD5SUM _file.

At a later step, the action will compare _MD5SUM_ file after the run of the script and the existing _MD5SUM_ file at the repository and if they’re different it means that new versions of kernel and/or driver combinations exist but they’re not built and published yet, so **update_dockerile.sh** will be run to change data at **Dockerfile** and Konflux _pipelineRun_ with the new version, and the new matrix and its _MD5SUM_ will be pushed to the repository in the same action.

After this the _pipelineRun_ will detect the previous push action (configured to be triggered with a specific subject) and will fire up the Konflux pipeline that will build and push the new driver version.

Note that driver-toolkit:5.14.0-284.51.1.el9_2 is the first version with the needed g++ compiler to build NVIDIA drivers.

