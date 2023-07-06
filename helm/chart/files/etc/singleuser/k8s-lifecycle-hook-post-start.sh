#/bin/bash
# See https://github.com/neurohackademy/nh2020-jupyterhub/blob/26ed5863d9fbbdb22e0ad4892eb764e35a65431f/chart/files/etc/singleuser/k8s-lifecycle-hook-post-start.sh

# Sync the examples folder, but don't stop the launch if this fails.
echo "Pulling examples"
/srv/conda/envs/notebook/bin/gitpuller https://github.com/microsoft/PlanetaryComputerExamples main /home/jovyan/PlanetaryComputerExamples || true

echo "Setting markdown config"
# Ensure that markdown files are rendered by default.
if [ ! -f ~/.jupyter/lab/user-settings/\@jupyterlab/docmanager-extension/plugin.jupyterlab-settings ]; then
    mkdir -p ~/.jupyter/lab/user-settings/\@jupyterlab/docmanager-extension/ || true
    echo '{defaultViewers: {markdown: "Markdown Preview"}}' > ~/.jupyter/lab/user-settings/\@jupyterlab/docmanager-extension/plugin.jupyterlab-settings
fi

# https://github.com/jupyterlab/jupyterlab/issues/10840
# Work around cell rendering issue by disabling that optimization.
mkdir -p /srv/conda/envs/notebook/share/jupyter/lab/settings/
echo '{"@jupyterlab/notebook-extension:tracker": {"renderCellOnIdle": false,"numberCellsToRenderDirectly": 10000000000000}}' > /srv/conda/envs/notebook/share/jupyter/lab/settings/overrides.json

# Add a sitecustomize module to execute on startup
# Silence dask-gateway warning. Fixed in https://github.com/dask/dask-gateway/pull/416.
echo 'import warnings; warnings.filterwarnings("ignore", "format_bytes")' >> /srv/conda/envs/notebook/lib/python3.8/site-packages/sitecustomize.py

echo "Disabling news"
mkdir -p /home/jovyan/.jupyter/lab/user-settings/@jupyterlab/apputils-extension/
cat <<EOF > /home/jovyan/.jupyter/lab/user-settings/@jupyterlab/apputils-extension/notification.jupyterlab-settings
{"fetchNews": "false"}
EOF

echo "Removing lost+found"
# Remove empty lost+found directories
rmdir ~/lost+found/ || true
