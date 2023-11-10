node {
    def app
    
    stage('Clone repository') { // for display purposes
        cleanWs()
        //git branch: 'main', changelog: false, poll: false, url: 'https://github.com/dddmaster/docker_samba_ad.git'
        checkout scm
    }
    stage('test') {
        sh 'ls'
        
    }
    /*stage('Build') {
        app = docker.build "dddmaster/samba-ad"
    }
    
    stage('push') {
        // This step should not normally be used in your script. Consult the inline help for details.
        withDockerRegistry(credentialsId: 'b1ff82ae-99c2-424a-997b-4841d63e3451') {
            app.push('latest')
        }
        
    }*/
}
