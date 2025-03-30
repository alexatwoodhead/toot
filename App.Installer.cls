/// From Common Template to add namespace and database
Class App.Installer
{

XData setup
{
<Manifest>
  <Default Name="Namespace" Value="TOOT"/>
  <Default Name="database" Value="toot"/>
  
  <Namespace Name="${Namespace}" Code="${Namespace}" Data="${Namespace}" Create="yes" Ensemble="1">
    <Configuration>
      <Database Name="${Namespace}" Dir="${mgrdir}${database}/" Create="yes"/>
    </Configuration>
     <CSPApplication Url="/csp/${app}" Directory="${cspdir}${app}"  ServeFiles="1" Recurse="1" AuthenticationMethods="32" />
  </Namespace>
</Manifest>
}

ClassMethod setup(ByRef pVars, pLogLevel As %Integer = 3, pInstaller As %Installer.Installer, pLogger As %Installer.AbstractLogger) As %Status [ CodeMode = objectgenerator, Internal ]
{
  #; Let XGL document generate code for this method. 
  Quit ##class(%Installer.Manifest).%Generate(%compiledclass, %code, "setup")
}

}
