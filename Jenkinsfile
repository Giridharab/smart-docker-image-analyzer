pipeline {
    agent any

    environment {
        IMAGE_NAME = "docker-analyze-pr-${env.BUILD_ID}"
        GITHUB_CREDENTIALS = credentials('GITHUB_CREDENTIALS') // GitHub token
        //OPENAI_API_KEY = credentials('OPENAI_API_KEY')   // Optional for AI suggestions
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/Giridharab/smart-docker-image-analyzer.git',
                    credentialsId: 'GITHUB_CREDENTIALS'
            }
        }

        stage('Detect Dockerfile') {
            steps {
                script {
                    dockerfilePath = sh(
                        script: "find . -name Dockerfile | head -n 1",
                        returnStdout: true
                    ).trim()

                    if (!dockerfilePath) {
                        error "❌ No Dockerfile found in repository"
                    }

                    echo "✅ Dockerfile found at: ${dockerfilePath}"
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh "docker build -f ${dockerfilePath} -t ${env.IMAGE_NAME} ."
                }
            }
        }

        stage('Analyze Docker Image') {
            steps {
                script {
                    // Layer analysis
                    layers = sh(
                        script: "docker history ${env.IMAGE_NAME} --format 'ID: {{.ID}} | Command: {{.CreatedBy}} | Size: {{.Size}}'",
                        returnStdout: true
                    ).trim()

                    // Vulnerabilities
                    vulnerabilities = sh(
                        script: "trivy image --exit-code 0 --no-progress ${env.IMAGE_NAME}",
                        returnStdout: true
                    ).trim()

                    // Binary check
                    binary = sh(
                        script: "docker run --rm ${env.IMAGE_NAME} sh -c 'ls /app || echo \"\"'",
                        returnStdout: true
                    ).trim()

                    binaryInfo = binary ? sh(
                        script: "docker run --rm ${env.IMAGE_NAME} sh -c 'ldd /app/${binary} 2>&1 || echo \"Binary is static ✅\"'",
                        returnStdout: true
                    ).trim() : "No /app binary found"

                    // SSL check
                    sslInfo = sh(
                        script: "docker run --rm ${env.IMAGE_NAME} sh -c '[ -f /etc/ssl/certs/ca-certificates.crt ] && echo \"✅ SSL certificates present\" || echo \"⚠️ SSL certificates missing\"'",
                        returnStdout: true
                    ).trim()

                    // Heuristic recommendations
                    recommendations = []
                    dockerfileContent = readFile(dockerfilePath)

                    if (dockerfileContent.contains("scratch")) {
                        recommendations << "✅ Using scratch: minimal runtime image"
                    } else {
                        recommendations << "⚠️ Consider using scratch or distroless for smaller and more secure runtime images"
                    }

                    recommendations << "- Use `go build -trimpath -ldflags='-s -w'` to reduce Go binary size"
                    recommendations << "- Use .dockerignore to avoid copying unnecessary files"

                    if (sslInfo.contains("missing")) {
                        recommendations << "⚠️ SSL certs missing: copy ca-certificates.crt or use distroless base"
                    }

                    // Optional: AI suggestions (external Python)
                    if (env.OPENAI_API_KEY) {
                        sh """
                        export DOCKERFILE_CONTENT='${dockerfileContent.replaceAll("'", "\\\\'")}'
                        export LAYERS='${layers.replaceAll("'", "\\\\'")}'
                        export BINARY_INFO='${binaryInfo.replaceAll("'", "\\\\'")}'
                        export SSL_INFO='${sslInfo.replaceAll("'", "\\\\'")}'
                        python3 dockerfile_ai_review.py
                        """
                        if (fileExists("ai_suggestions.txt")) {
                            recommendations << "\n💡 AI Suggestions:\n" + readFile("ai_suggestions.txt")
                        }
                    }
                }
            }
        }
    } // <-- Close 'stages' properly here

    post {
        always {
            script {
                // Compile report
                report = """
                # Docker Image Analysis Report

                ## Dockerfile Path
                ${dockerfilePath}

                ## Image Layers
                ${layers}

                ## Vulnerabilities
                ${vulnerabilities}

                ## Binary Info
                ${binaryInfo}

                ## SSL Info
                ${sslInfo}

                ## Recommendations
                ${recommendations.join('\n')}
                """

                // Save report to file
                writeFile file: 'docker_image_report.md', text: report

                // Archive report
                archiveArtifacts artifacts: 'docker_image_report.md', fingerprint: true

                // Cleanup Docker image
                sh "docker rmi ${env.IMAGE_NAME} || true"
            }
        }
    }
}