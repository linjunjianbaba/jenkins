# Jenkinsfile语法

![img](https:////upload-images.jianshu.io/upload_images/7007629-7ab144cdbb97548a.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/847)

> Pipeline为用户设计了三个最最基本的概念：
>  **Stage**：一个Pipeline可以划分为若干个Stage，每个Stage代表一组操作。注意，Stage是一个逻辑分组的概念，可以跨多个Node。
>  **Node**：一个Node就是一个Jenkins节点，或者是Master，或者是Agent(过去叫做Slave)，是执行Step的具体运行期环境。
>  **Step**：Step是最基本的操作单元，小到创建一个目录，大到构建一个Docker镜像，由各类Jenkins Plugin提供。

>  Jenkins DSL结构的简单解释：
>
> 
>
> ![img](https:////upload-images.jianshu.io/upload_images/7007629-4d3a043d45d23278.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/896)

## 1. 常见的tool 'M3'究竟是啥玩意



![img](https:////upload-images.jianshu.io/upload_images/7007629-7ed7682c6b570965.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/784)

```
node {

git url: 'https://github.com/jglick/simple-maven-project-with-tests.git'
def mvnHome = tool 'M3'
env.PATH = "${mvnHome}/bin:${env.PATH}"
sh "${mvnHome}/bin/mvn -B -Dmaven.test.failure.ignore verify"
step([$class: 'ArtifactArchiver', artifacts: '**/target/*.jar', fingerprint: true])
step([$class: 'JUnitResultArchiver', testResults: '**/target/surefire-reports/TEST-*.xml'])
}
```

## 2. pipeline step中的几种等价的写法

> pipeline step总是接受命名参数(即 在调用函数时可以通过**指定参数名称**的方式来调用参数)，括号可以省略，也可以使用标准的groovy语法传入map作为参数

### 2.1 从github checkout源代码

```
#下面两个等价，第一个是简写
git url: 'https://github.com/jglick/simple-maven-project-with-tests.git'

checkout scm: [$class: 'GitSCM', branches: [[name: '*/master']], userRemoteConfigs: [[url: 'https://github.com/jglick/simple-maven-project-with-tests']]

#下面两个等价
git url: 'https://github.com/jglick/simple-maven-project-with-tests.git', branch: 'master'

git([url: 'https://github.com/jglick/simple-maven-project-with-tests.git', branch: 'master'])
```

### 2.2 unix下的sh命令

> 如果只有一个强制的参数，则可以省略参数名字

下面两个等价：

```
#等价
sh 'echo hello'

sh([script: 'echo hello'])
```

## 3.  使用函数，条件控制



![img](https:////upload-images.jianshu.io/upload_images/7007629-a4cf09bf6795d5d2.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1000)

```
node('remote') {
    git url: 'https://github.com/jglick/simple-maven-project-with-tests.git'
    def v = version()
    if (v) {
        echo "Building version ${v}"
    }
    def mvnHome = tool 'M3'
    sh "${mvnHome}/bin/mvn -B -Dmaven.test.failure.ignore verify"
    step([$class: 'ArtifactArchiver', artifacts: '**/target/*.jar', fingerprint: true])
    step([$class: 'JUnitResultArchiver', testResults: '**/target/surefire-reports/TEST-*.xml'])
}
def version() {
    def matcher = readFile('pom.xml') =~ '<version>(.+)</version>'
    matcher ? matcher[0][1] : null
}
```

# 4. 多线程

> parallel的调用需要传入map类型作为参数，map的key为名字，value为要执行的groovy脚本
>
> 
>
> ![img](https:////upload-images.jianshu.io/upload_images/7007629-20dec67c27b916e0.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1000)

```
node('remote') {
    git url: 'https://github.com/jenkinsci/parallel-test-executor-plugin-sample.git'
    archive 'pom.xml, src/'
}
def splits = splitTests([$class: 'CountDrivenParallelism', size: 2])
def branches = [:]
for (int i = 0; i < splits.size(); i++) {
    def exclusions = splits.get(i);
    branches["split${i}"] = {
        node('remote') {
            sh 'rm -rf *'
            unarchive mapping: ['pom.xml' : '.', 'src/' : '.']
            writeFile file: 'exclusions.txt', text: exclusions.join("\n")
            sh "${tool 'M3'}/bin/mvn -B -Dmaven.test.failure.ignore test"
            step([$class: 'JUnitResultArchiver', testResults: 'target/surefire-reports/*.xml'])
        }
    }
}
parallel branches
```

 Script Pipeline的结构说明：

![img](https:////upload-images.jianshu.io/upload_images/7007629-c5589d8ed64f1a54.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/369)

# 5. Declarative Pipeline试验例子1

```
pipeline {
    agent any
    environment {
        DEPLOY_TO = 'production'
    }
    stages {
        stage('Example Build') {
            steps {
                echo 'Hello World'
            }
        }

        stage('environment to test When') {
            when {
                allOf {
                    //branch 'production'
                    environment name: 'DEPLOY_TO', value: 'production'
                }
            }
            steps {
                echo 'Deploying'
            }
        }
    }
}

---------------------------
pipeline{
    agent any
    triggers {
        cron('H */4 * * 1-5')
    }//triggers { pollSCM('H 4/* 0 0 1-5') }


     tools {
        //工具名称必须在Jenkins 管理Jenkins → 全局工具配置中预配置。
        maven 'maven3'
    }    

    parameters{
        string(name:'Person Name', defaultValue:"YAY", description:'for example')
        booleanParam(name: 'DEBUG_BUILD', defaultValue: true, description: '')
    }

    environment {
        DEPLOY_TO = 'production'
    }

    
    stages{
//*******************************************************
        stage('Say Hello using Parameters')
        {
            steps{
                echo 'Hello ${params.Person Name}'
                echo '${params.DEBUG_BUILD}'
                }
        }
//*******************************************************
        //测试配置的那些tools在pipeline中的使用
        stage('Tools') 
        {
            steps {
                sh 'mvn --version'
            }
        }
//*******************************************************
        //测试when，也关注environment的使用
        stage('environment to test When') 
        {
            when {
                allOf {
                    //branch 'production'
                    environment name: 'DEPLOY_TO', value: 'production'
                }
            }
            steps {
                echo 'Deploying'
            }
        }

//*******************************************************
stage('Parallel Stage') {
            parallel {
                stage('Branch A') {
                    agent {
                        //label "for-branch-a"
                        label "master"
                    }

                    steps {
                        echo "On Branch A"
                    }
                }

                stage('Branch B') {
                    agent {
                        //label "for-branch-b"
                        label "master"
                    }

                    steps {
                        echo "On Branch B"
                    }
                }
            }
        }


//*********************************************************
stage('scriptInSteps') {
            steps {
                echo 'Hello World'
                //script步骤
                script {
                    def browsers = ['chrome', 'firefox','IE']
                    for (int i = 0; i < browsers.size(); ++i) {
                        echo "Testing the ${browsers[i]} browser"
                    }
                }

                //我尝试的写法，证明是OK的
                script{
                    def tasks =['CI','CD','Sonar','Run RF']
                    for(String task:tasks)
                    {
                        echo task
                    }
                }
                
                //我尝试的写法，证明也是OK的
                script{
                    String[] tasks =['CI2','CD2','Sonar2','Run RF2']
                    for(String task:tasks)
                    {
                        echo task
                    }
                }
            }
        }
    }
}
```

# 6. 真实例子：使用Declarative Pipeline做DailyCI

```
pipeline{
    agent any
     tools {
        //工具名称必须在Jenkins 管理Jenkins → 全局工具配置中预配置。
        maven 'maven3'
    }

    environment{     
        def SRCCODE_DIR = "/var/jenkins_home/workspace/${env.JOB_NAME}"
        def DAILYCI_DIR = "/var/ciOutput/dailyCiOutput"
        def SVN_FOLD = "personrecord"  
    }

    triggers { cron('H 0,12 * * *') }

    stages{     
        stage('Checkout'){
             steps{
    
                checkout([
                      $class: 'SubversionSCM', 
                      additionalCredentials: [], 
                      excludedCommitMessages: '', 
                      excludedRegions: '', 
                      excludedRevprop: '', 
                      excludedUsers: '', 
                      filterChangelog: false, 
                      ignoreDirPropChanges: false, 
                      includedRegions: '', 
                      locations: [[credentialsId: '6aab1014-b1c9-4a8a-adba-f1cd0d27a483', 
                                   depthOption: 'infinity', 
                                   ignoreExternalsOption: true,                                    
                                   remote: "https://10.45.136.230/svn/ZYN/HGARCH/branch/V1.0/code/personrecord"]], 
                      workspaceUpdater: [$class: 'UpdateUpdater']])
            }
        }

        stage('Build'){
            steps{
                compileAllFiles()                                          
            }           
        }

        stage('Backend Unit Test') {
            steps {
                sh 'mvn -f $SVN_FOLD/algorithm/pom.xml test'
                sh 'mvn -f $SVN_FOLD/pom.xml test'

                //junit '**/target/surefire-reports/TEST-*.xml'
                //archive 'target/*.jar'                    
            }
        }


        stage('UploadToRepository'){
            steps{                  
                    rmDailyCIOutputFiles() 
                    copyJarsToDailyCIOutoutDir()               
            }   
        }
        stage('Depoly to 117'){
            steps{
                //调用Publish Over SSH插件，上传docker-compose.yaml文件并且执行deploy脚本
            sshPublisher(publishers: [sshPublisherDesc(configName: 'forchongqing117', transfers: [sshTransfer(cleanRemote: false, excludes: '', execCommand: 'sh /root/hgarchDevops/redeploy.sh', execTimeout: 120000, flatten: false, makeEmptyDirs: false, noDefaultExcludes: false, patternSeparator: '[, ]+', remoteDirectory: '/root/hgarchDevops/dailyOutput', remoteDirectorySDF: false, removePrefix: '', sourceFiles: 'output/*.*')], usePromotionTimestamp: false, useWorkspaceInPromotion: false, verbose: false)])

            }
        }
    }

    post {      
        failure
            {
                sh '$mail'
            }       
    }
}
def compileAllFiles()
{
    //执行shell命令
    sh 'mvn -f $SVN_FOLD/algorithm/pom.xml clean scala:compile compile package -DskipTests=true'
    sh 'mvn -f $SVN_FOLD/pom.xml clean package' 
}

def rmDailyCIOutputFiles()
{   
    sh 'rm -rf $DAILYCI_DIR.'
}
def copyJarsToDailyCIOutoutDir()
{
    if (isUnix())
    {
        sh 'cp $SVN_FOLD/output/*.jar $DAILYCI_DIR'             
    }
    else
    {       
        bat 'cp $SVN_FOLD/output/*.jar $DAILYCI_DIR'
    }   
}

def mail=
{
    emailext body: emailBody(),//"${env.DEFAULT_CONTENT}",
    recipientProviders: [ //[$class: 'CulpritsRecipientProvider'],
    //[$class: 'DevelopersRecipientProvider'],
    //[$class: 'RequesterRecipientProvider'],
    //[$class: 'FailingTestSuspectsRecipientProvider'],
    [$class: 'FirstFailingBuildSuspectsRecipientProvider'],
    [$class: 'UpstreamComitterRecipientProvider']
    ],
    subject: '构建失败',
    mimeType: "text/html"
}

def emailBody()
{
    return '''<!DOCTYPE html>    
    <html>    
    <head>    
    <meta charset="UTF-8">    
    <title>${ENV, var="JOB_NAME"}-第${BUILD_NUMBER}次构建日志</title>    
    </head>    
        
    <body leftmargin="8" marginwidth="0" topmargin="8" marginheight="4"    
        offset="0">    
        <table width="95%" cellpadding="0" cellspacing="0"  style="font-size: 11pt; font-family: Tahoma, Arial, Helvetica, sans-serif">    
            <tr>    
                本邮件由系统自动发出，无需回复！<br/>            
                各位同事，大家好，以下为${PROJECT_NAME }项目构建信息</br> 
                <td><font color="#CC0000">构建结果 - ${BUILD_STATUS}</font></td>   
            </tr>    
            <tr>    
                <td><br />    
                <b><font color="#0B610B">构建信息</font></b>    
                <hr size="2" width="100%" align="center" /></td>    
            </tr>    
            <tr>    
                <td>    
                    <ul>    
                        <li>项目名称 ： ${PROJECT_NAME}</li>    
                        <li>构建编号 ： 第${BUILD_NUMBER}次构建</li>    
                        <li>触发原因： ${CAUSE}</li>    
                        <li>构建状态： ${BUILD_STATUS}</li>    
                        <li>构建日志： <a href="${BUILD_URL}console">${BUILD_URL}console</a></li>    
                        <li>构建  Url ： <a href="${BUILD_URL}">${BUILD_URL}</a></li>    
                        <li>工作目录 ： <a href="${PROJECT_URL}ws">${PROJECT_URL}ws</a></li>    
                        <li>项目  Url ： <a href="${PROJECT_URL}">${PROJECT_URL}</a></li>    
                    </ul>    

    <h4><font color="#0B610B">失败用例</font></h4>
    <hr size="2" width="100%" />
    $FAILED_TESTS<br/>

    <h4><font color="#0B610B">最近提交(#$SVN_REVISION)</font></h4>
    <hr size="2" width="100%" />
    <ul>
    ${CHANGES_SINCE_LAST_SUCCESS, reverse=true, format="%c", changesFormat="<li>%d [%a] %m</li>"}
    </ul>
    详细提交: <a href="${PROJECT_URL}changes">${PROJECT_URL}changes</a><br/>

                </td>    
            </tr>    
        </table>    
    </body>    
    </html>'''
}
```

![img](https:////upload-images.jianshu.io/upload_images/7007629-badebbcbcdea0a00.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1000)