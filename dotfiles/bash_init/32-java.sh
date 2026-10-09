# java-specific configuration

# on this box I need java 17
setpath -er JAVA_HOME /usr/lib/jvm/java-17-amazon-corretto ||
    setpath -er JAVA_HOME /usr/lib/jvm/java-17-openjdk-amd64 ||
    return 0
