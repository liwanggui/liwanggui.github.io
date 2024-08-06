# Maven 多仓库配置


maven 多仓库配置需要在 `profile` 节点进行配置，配置方法如下：

编辑 maven 配置文件 `settings.xml` 添加如下配置

```xml
<?xml version="1.0" encoding="UTF-8"?>

<settings xmlns="http://maven.apache.org/SETTINGS/1.2.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.2.0 https://maven.apache.org/xsd/settings-1.2.0.xsd">
  
  <servers> 
    <!-- 当我们仓库需要身份验证时可以在此配置身份验证信息 -->
    <server>
      <id>maven-nexus3</id>
      <username>xxx</username>
      <password>xxxx</password>
    </server>
  </servers>

  <mirrors>
    <!-- 配置Maven仓库代理加速站点 -->
    <mirror>
      <id>maven-nexus3</id>
      <name>自建内部仓库</name>
      <!-- 
        如果是 * 默认所有仓库都走代理，
        可以把不需要走代理的仓库使用!加仓库ID方法，让其不走代理 
      -->
      <mirrorOf>*,!osgeo,!osgeo2</mirrorOf>
      <url>https://maven.liwanggui.com/repository/maven-public/</url>
    </mirror>
  </mirrors>

  <profiles>
  <!-- 多仓库配置需要使用 profile 节点进行配置 -->
    <profile>
        <!-- ID必须唯一 -->
        <id>osgeoreleaseRepo</id>
        <repositories>
            <repository>
                <id>osgeo</id>
                <name>OSGeo Release Repository</name>
                <url>https://repo.osgeo.org/repository/release/</url>
                <snapshots><enabled>false</enabled></snapshots>
                <releases><enabled>true</enabled></releases>
            </repository>
        </repositories>
    </profile>

    <profile>
        <id>osgeosnapshotRepo</id>
        <repositories>
            <repository>
                <id>osgeo2</id>
                <name>OSGeo Snapshot Repository</name>
                <url>https://repo.osgeo.org/repository/snapshot/</url>
                <snapshots><enabled>true</enabled></snapshots>
                <releases><enabled>false</enabled></releases>
            </repository>
        </repositories>
    </profile>
  </profiles>

    <activeProfiles>
        <!-- 启用仓库 -->
        <activeProfile>osgeoreleaseRepo</activeProfile>
        <activeProfile>osgeosnapshotRepo</activeProfile>
    </activeProfiles>
</settings>
```
