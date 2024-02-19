# parent image
FROM rocker/shiny-verse

# Set the working directory in the container
WORKDIR /app

# Copy the entire project directory into the container
COPY . /app

# Install any needed packages specified in the R file
RUN R -e "install.packages(c('shiny', 'bslib', 'tidyverse', 'bsicons', 'sf', 'leaflet', 'thematic'), dependencies=TRUE)"

# Make port 3838 available to the world outside this container
EXPOSE 3838

# Run app.R when the container launches
CMD ["R", "-e", "shiny::runApp('/app/app.R', host='0.0.0.0', port=3838)"]
