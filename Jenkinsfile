pipeline 
{
     agent any

     environment
     {
        // Docker Hub credentials ID stored in Jenkins
        DOCKERHUB_CREDENTIALS = 'cweb_2140'
        IMAGE_NAME = 'jacjamg/homework_02:latest'
     }

    stages 
    {
        stage('Cloning Git')
        {
            steps
            {
                checkout scm
            }
        }

        stage('SAST')
        {
            steps
            {
                sh 'echo Running SAST scan...'
            }
        }

        stage('BUILD-AND-TAG')
        {
            agent{ label 'CWEB2140-app-server'}
            steps
            {
                script
                {
                    // Build Docker image using Jenkins Docker Pipeline API
                    echo "Building Docker image ${IMAGE_NAME}"
                    app = docker.build("${IMAGE_NAME}")
                    app.tag("latest")
                }
                
            }
        }


        stage('POST-TO-DOCKERHUB')
        {
            agent{ label 'CWEB2140-app-server'}
            steps
            {
                script
                {
                    // Build Docker image using Jenkins Docker Pipeline API
                    echo "Pushing image ${IMAGE_NAME}:latest to Docker Hub..."
                    docker.withRegistry('https://registry.hub.docker.com', "${DOCKERHUB_CREDENTIALS}")
                    {
                        app.push("latest")
                    }
                    
                }               
            }
        }

        
        stage('DEPLOYMENT')
        {
            agent{ label 'CWEB2140-app-server'}
            steps
            {
                echo "Starting deployment using docker-compose..."

                    script
                    {
                        dir("${WORKSPACE}")
                        {
                            sh'''
                                docker-compose down
                                docker-compose up -d
                                docker ps
                            '''
                        }
                          
                    }  
                echo "Deployment completed successfully!"
                             
            }
        }
    }
}
