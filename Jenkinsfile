podTemplate(label: 'slave', cloud: 'kubernetes', serviceAccount: 'jenkins-admin', containers: [
    containerTemplate(
        name: 'jnlp', 
        image: 'jenkins/jenkins-slave:1.0.1', 
        alwaysPullImage: false, 
        args: '${computer.jnlpmac} ${computer.name}'),

  ],
  volumes: [
    hostPathVolume(mountPath: '/var/run/docker.sock', hostPath: '/var/run/docker.sock'),
],) 
{
    node('slave') {
        stage('kubectl') {
            stage('show pod') {
                sh 'kubectl get pods'
            }
            stage('show images'){
                sh 'docker images'
            }
            stage('git clone') {
                git 'https://github.com/linjunjianbaba/binlog2sql.git'
            }
        }
    }
}