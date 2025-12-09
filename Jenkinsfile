pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIALS = 'cweb_2140'
        IMAGE_NAME = 'jacjamg/final_node'

        TRIVY_SEVERITY = "HIGH,CRITICAL"

        TARGET_URL = "http://172.234.200.182/"
        REPORT_HTML = "zap_report.html"
        REPORT_JSON = "zap_report.json"
        ZAP_IMAGE = "ghcr.io/zaproxy/zaproxy:stable"
        REPORT_DIR = "${env.WORKSPACE}/zap_reports"
        SECRET = "${SNYK_SECRET}"
        CREDENTIALS = "${SNYK_CREDENTIALS}"
    }

    stages {

        stage('Cloning Git') {
            steps {
                
                    checkout scm
                }
        }


        /* -------------------------------------------------------------------
           SNYK (NON-BLOCKING)
        -------------------------------------------------------------------*/
        stage('SAST-TEST') {
            steps {
                script {
                    echo "Running Snyk (non-blocking)..."
                    catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
                         withCredentials([string(credentialsId: "${CREDENTIALS}", variable: 'jenkins-snyk')]){
                            snykSecurity(
                                snykInstallation: 'Snyk-installations@latest',
                                snykTokenId: "${SECRET}",
                                severity: 'critical'
                            )
                         }

                    }
                }
            }
        }

//         stage('SAST-TEST') {
//     steps {
//         script {
//             echo "Running Snyk..."

//             catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
//                 snykSecurity(
//                     severity: 'critical'
//                 )
//             }
//         }
//     }
// }


        /* -------------------------------------------------------------------
           SONARQUBE (NON-BLOCKING)
        -------------------------------------------------------------------*/
        stage('SonarQube Analysis') {
            agent { label 'CWEB2140-app-server' }
            steps {
                script {
                    catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
                        def scannerHome = tool 'SonarQube-Scanner'
                        withSonarQubeEnv('SonarQube-installations') {
                            sh """
                                ${scannerHome}/bin/sonar-scanner \
                                -Dsonar.projectKey=gameapp \
                                -Dsonar.sources=.
                            """
                        }
                    }
                }
            }
        }

        /* -------------------------------------------------------------------
           DOCKER BUILD (BLOCKING)
        -------------------------------------------------------------------*/
        stage('BUILD-AND-TAG') {
            agent { label 'CWEB2140-app-server' }
            steps {
                script {
                    echo "Building Docker image ${IMAGE_NAME}..."
                    app = docker.build("${IMAGE_NAME}")
                    app.tag("latest")
                }
            }
        }

        /* -------------------------------------------------------------------
           PUSH TO DOCKER HUB (BLOCKING)
        -------------------------------------------------------------------*/
        stage('POST-TO-DOCKERHUB') {
            agent { label 'CWEB2140-app-server' }
            steps {
                script {
                    echo "Pushing to DockerHub..."
                    docker.withRegistry('https://registry.hub.docker.com', "${DOCKERHUB_CREDENTIALS}") {
                        app.push("latest")
                    }
                }
            }
        }

        /* -------------------------------------------------------------------
           TRIVY SCAN (NON-BLOCKING)
        -------------------------------------------------------------------*/
        stage("SECURITY-IMAGE-SCANNER") {
            steps {
                script {
                    echo "Running Trivy scan..."

                    catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {

                        sh """
                            docker run --rm -v \$(pwd):/workspace aquasec/trivy:latest image \
                            --exit-code 0 \
                            --format json \
                            --output /workspace/trivy-report.json \
                            --severity ${TRIVY_SEVERITY} \
                            ${IMAGE_NAME}
                        """

                        sh """
                            docker run --rm -v \$(pwd):/workspace aquasec/trivy:latest image \
                            --exit-code 0 \
                            --format template \
                            --template "@/contrib/html.tpl" \
                            --output /workspace/trivy-report.html \
                            ${IMAGE_NAME}
                        """
                    }

                    archiveArtifacts artifacts: "trivy-report.json,trivy-report.html"
                }
            }
        }

        /* -------------------------------------------------------------------
           TRIVY SUMMARY (NON-BLOCKING)
        -------------------------------------------------------------------*/
        stage("Summarize Trivy Findings") {
            steps {
                script {
                    catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {

                        if (!fileExists("trivy-report.json")) {
                            echo "No Trivy report."
                            return
                        }

                        def highCount = sh(
                            script: "grep -o '\"Severity\": \"HIGH\"' trivy-report.json | wc -l",
                            returnStdout: true
                        ).trim()

                        def criticalCount = sh(
                            script: "grep -o '\"Severity\": \"CRITICAL\"' trivy-report.json | wc -l",
                            returnStdout: true
                        ).trim()

                        echo "HIGH: ${highCount}"
                        echo "CRITICAL: ${criticalCount}"
                    }
                }
            }
        }

        /* -------------------------------------------------------------------
           ZAP BASELINE SCAN (NON-BLOCKING)
        -------------------------------------------------------------------*/
        stage('DAST') {
            steps {
                script {
                    echo "Running OWASP ZAP..."

                    sh "mkdir -p ${REPORT_DIR}"

                    // NEVER FAIL ZAP
                    catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
                        sh """
                            docker run --rm --user root --network host \
                            -v ${REPORT_DIR}:/zap/wrk \
                            -t ${ZAP_IMAGE} zap-baseline.py \
                            -t ${TARGET_URL} \
                            -r ${REPORT_HTML} -J ${REPORT_JSON} || true
                        """
                    }

                    archiveArtifacts artifacts: "zap_reports/*", allowEmptyArchive: true
                }
            }
        }

        /* -------------------------------------------------------------------
           DEPLOYMENT — MUST ALWAYS RUN
        -------------------------------------------------------------------*/
        stage('DEPLOYMENT') {
            agent { label 'CWEB2140-app-server' }
            steps {
                script {
                    echo "Deploying using docker-compose..."

                    catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
                        dir("${WORKSPACE}") {
                            sh """
                                docker-compose down || true
                                docker-compose up -d || true
                                docker ps || true
                            """
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            publishHTML(target: [
                reportName: 'Trivy Image Security Report',
                reportDir: '.',
                reportFiles: 'trivy-report.html',
                alwaysLinkToLastBuild: true
            ])

            publishHTML(target: [
                reportName: 'OWASP ZAP DAST Report',
                reportDir: 'zap_reports',
                reportFiles: 'zap_report.html',
                alwaysLinkToLastBuild: true
            ])
        }
    }
}

// pipeline 
// {
//      agent any
 

     
//      environment
//      {
//         // Docker Hub credentials ID stored in Jenkins
//         DOCKERHUB_CREDENTIALS = 'cweb_2140'
//         IMAGE_NAME = 'jacjamg/final_node:latest'
//      }

//     stages 
//     {
//         stage('Cloning Git')
//         {
//             steps
//             {
//                 checkout scm
//             }
//         }

//         stage('SAST')
//         {
//             steps
//             {
//                 sh 'echo Running SAST scan...'
//             }
//         }

//         stage('BUILD-AND-TAG')
//         {
//             agent{ label 'CWEB2140-app-server'}
//             steps
//             {
//                 script
//                 {
//                     // Build Docker image using Jenkins Docker Pipeline API
//                     echo "Building Docker image ${IMAGE_NAME}"
//                     app = docker.build("${IMAGE_NAME}")
//                     app.tag("latest")
//                 }
                
//             }
//         }


//         stage('POST-TO-DOCKERHUB')
//         {
//             agent{ label 'CWEB2140-app-server'}
//             steps
//             {
//                 script
//                 {
//                     // Build Docker image using Jenkins Docker Pipeline API
//                     echo "Pushing image ${IMAGE_NAME}:latest to Docker Hub..."
//                     docker.withRegistry('https://registry.hub.docker.com', "${DOCKERHUB_CREDENTIALS}")
//                     {
//                         app.push("latest")
//                     }
                    
//                 }               
//             }
//         }

        
//         stage('DEPLOYMENT')
//         {
//             agent{ label 'CWEB2140-app-server'}
//             steps
//             {
//                 echo "Starting deployment using docker-compose..."

//                     script
//                     {
//                         dir("${WORKSPACE}")
//                         {
//                             sh'''
//                                 docker-compose down
//                                 docker-compose up -d
//                                 docker ps
//                             '''
//                         }
                          
//                     }  
//                 echo "Deployment completed successfully!"
                             
//             }
//         }
//     }
// }
