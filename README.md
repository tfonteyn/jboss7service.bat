jboss7service.bat
=================

service.bat script for installing JBoss 7 / EAP 6 as a windows service

Red Hat JBoss EAP 6 Service Script for Windows
Usage:

  service install <options>  , where the options are:

    /startup                  : Set the service to auto start
                                Not specifying sets the service to manual

    /jbossuser <username>     : JBoss username to use for the shutdown command.
    /jbosspass <password>     : Password for /jbossuser

    /controller <host:port>   : The host:port of the management interface.
                                default: localhost:9999

    /host [<domainhost>]      : Indicates that domain mode is to be used with an

                                optional domain controller name.
                                default: master
                                Not specifying /host will install JBoss in
                                standalone mode.

Options to use when multiple services or different accounts are needed:

    /name <servicename>       : The name of the service

                                default: JBossEAP6
    /desc <description>       : The description of the service, use double
                                quotes to allow spaces.
                                Maximum 1024 characters.
                                default: JBoss Enterprise Application Platform 6


    /serviceuser <username>   : Specifies the name of the account under which
                                the service should run.
                                Use an account name in the form of
                                DomainName\UserName
                                default: not used, the service runs as
                                Local System Account.
    /servicepass <password>   : password for /serviceuser

Advanced options:

    /config <xmlfile>         : The server-config to use
                                default: standalone.xml / domain.xml
    /hostconfig <xmlfile>     : domain mode only, the host config to use
                                default: host.xml

    /base <directory>         : The base directory for server/domain content
                                default: standalone / domain

    /loglevel <level>         : The log level for the service:  Error, Info,
                                Warn or Debug (Case insensitive)
                                default: INFO
    /logpath <path>           : Path of the log
                                default depends on domain or standalone mode
                                /base applies when /logpath is not set.
                                  C:\jboss\624\domain\log
                                  C:\jboss\624\standalone\log

    /debug                    : run the service install in debug mode

Other commands:

  service uninstall [/name <servicename>]

  service start [/name <servicename>]

  service stop [/name <servicename>]

  service restart [/name <servicename>]

    /name  <servicename>      : Name of the service: should not contain spaces
                                default: JBossEAP6

