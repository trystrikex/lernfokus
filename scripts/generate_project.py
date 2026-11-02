from pathlib import Path
import plistlib, hashlib, subprocess, json
root = Path(__file__).resolve().parent.parent
project_file = root/'Fokus.xcodeproj/project.pbxproj'
previous_settings = {}
if project_file.exists():
    previous = json.loads(subprocess.check_output(['plutil', '-convert', 'json', '-o', '-', str(project_file)]))['objects']
    for target in previous.values():
        if target.get('isa') == 'PBXNativeTarget':
            for config_id in previous[target['buildConfigurationList']]['buildConfigurations']:
                config = previous[config_id]
                previous_settings[(target['name'], config['name'])] = config['buildSettings']
objects = {}
def uid(s): return hashlib.sha1(s.encode()).hexdigest()[:24].upper()
def obj(key, value): objects[uid(key)] = value; return uid(key)
def arr(values): return '(' + ', '.join(values) + ',)'
def quote(s): return '"' + s + '"'
products=[]; targets=[]; groups=[]
shared=['Shared/FocusSession.swift','Shared/SessionStore.swift','Shared/FocusAttributes.swift']
configs = [('Fokus','com.apple.product-type.application','app',['Fokus/FokusApp.swift','Fokus/FocusController.swift','Fokus/FocusView.swift']+shared),('FocusLiveActivity','com.apple.product-type.app-extension','appex',['LiveActivity/FocusWidget.swift',shared[2]])]
for name,typ,ext,files in configs:
    folder={'Fokus':'Fokus','FocusMonitor':'Monitor','FocusLiveActivity':'LiveActivity'}[name]
    info={'CFBundleDisplayName':'Fokus','CFBundleIdentifier':'$(PRODUCT_BUNDLE_IDENTIFIER)','CFBundleExecutable':'$(EXECUTABLE_NAME)','CFBundleName':'$(PRODUCT_NAME)','CFBundlePackageType':'APPL' if ext=='app' else 'XPC!','CFBundleShortVersionString':'1.0','CFBundleVersion':'1'}
    if ext=='app': info.update({'NSSupportsLiveActivities':True,'UILaunchScreen':{},'UIApplicationSceneManifest':{'UIApplicationSupportsMultipleScenes':False},'UISupportedInterfaceOrientations':['UIInterfaceOrientationPortrait']})
    else:
        info['NSExtension']={'NSExtensionPointIdentifier':'com.apple.deviceactivity.monitor-extension' if name=='FocusMonitor' else 'com.apple.widgetkit-extension'}
        if name=='FocusMonitor': info['NSExtension']['NSExtensionPrincipalClass']='$(PRODUCT_MODULE_NAME).FocusMonitor'
    (root/folder/'Info.plist').write_bytes(plistlib.dumps(info))
    ent={}
    (root/folder/f'{name}.entitlements').write_bytes(plistlib.dumps(ent))
    refs=[]; builds=[]
    for f in files:
        ref=obj('file'+f, f'isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {quote(f)}; sourceTree = SOURCE_ROOT;')
        refs.append(ref)
        builds.append(obj(name+f, f'isa = PBXBuildFile; fileRef = {ref};'))
    groups.extend(refs)
    source=obj(name+'sources',f'isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = {arr(builds)}; runOnlyForDeploymentPostprocessing = 0;')
    product=obj(name+'product',f'isa = PBXFileReference; explicitFileType = wrapper.{"application" if ext=="app" else "app-extension"}; path = {name}.{ext}; sourceTree = BUILT_PRODUCTS_DIR;')
    products.append(product)
    confs=[]
    for mode in ['Debug','Release']:
        settings={'PRODUCT_NAME':'$(TARGET_NAME)','PRODUCT_BUNDLE_IDENTIFIER':'de.fokuslern.app'+('' if name=='Fokus' else '.'+name),'INFOPLIST_FILE':folder+'/Info.plist','CODE_SIGN_ENTITLEMENTS':folder+'/'+name+'.entitlements','CODE_SIGN_STYLE':'Automatic','SWIFT_VERSION':'5.0','IPHONEOS_DEPLOYMENT_TARGET':'17.0','TARGETED_DEVICE_FAMILY':'1','SDKROOT':'iphoneos','SWIFT_OPTIMIZATION_LEVEL':'-Onone' if mode=='Debug' else '-O','GENERATE_INFOPLIST_FILE':'NO','LD_RUNPATH_SEARCH_PATHS':'$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks'}
        for key in ['DEVELOPMENT_TEAM', 'PRODUCT_BUNDLE_IDENTIFIER', 'CODE_SIGN_IDENTITY', 'PROVISIONING_PROFILE_SPECIFIER']:
            if key in previous_settings.get((name, mode), {}):
                settings[key] = previous_settings[(name, mode)][key]
        if 'DEVELOPMENT_TEAM' not in settings:
            team = previous_settings.get(('Fokus', mode), {}).get('DEVELOPMENT_TEAM')
            if team: settings['DEVELOPMENT_TEAM'] = team
        if ext=='app': settings['ASSETCATALOG_COMPILER_APPICON_NAME']='AppIcon'
        if ext!='app': settings.update({'APPLICATION_EXTENSION_API_ONLY':'YES','SKIP_INSTALL':'YES'})
        confs.append(obj(name+mode,'isa = XCBuildConfiguration; name = '+mode+'; buildSettings = {'+' '.join(k+' = '+quote(v)+';' for k,v in settings.items())+'};'))
    cl=obj(name+'configs',f'isa = XCConfigurationList; buildConfigurations = {arr(confs)}; defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;')
    phases=[source]; deps=[]
    if name=='Fokus':
        assets=obj('assets', 'isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = "Fokus/Assets.xcassets"; sourceTree = SOURCE_ROOT;')
        groups.append(assets)
        asset_build=obj('assetsbuild', f'isa = PBXBuildFile; fileRef = {assets};')
        phases.append(obj('resources', f'isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = ({asset_build},); runOnlyForDeploymentPostprocessing = 0;'))
        embed=[]
        for child in ['FocusLiveActivity']:
            embed.append(obj('embed'+child,f'isa = PBXBuildFile; fileRef = {uid(child+"product")}; settings = {{ATTRIBUTES = (RemoveHeadersOnCopy,);}};'))
            proxy=obj('proxy'+child,f'isa = PBXContainerItemProxy; containerPortal = {uid("project")}; proxyType = 1; remoteGlobalIDString = {uid(child+"target")}; remoteInfo = {child};')
            deps.append(obj('dep'+child,f'isa = PBXTargetDependency; target = {uid(child+"target")}; targetProxy = {proxy};'))
        phases.append(obj('embedphase',f'isa = PBXCopyFilesBuildPhase; buildActionMask = 2147483647; dstPath = ""; dstSubfolderSpec = 13; files = {arr(embed)}; name = "Embed App Extensions"; runOnlyForDeploymentPostprocessing = 0;'))
    targets.append(obj(name+'target',f'isa = PBXNativeTarget; buildConfigurationList = {cl}; buildPhases = {arr(phases)}; buildRules = (); dependencies = {arr(deps) if deps else "()"}; name = {name}; productName = {name}; productReference = {product}; productType = {quote(typ)};'))
pg=obj('products',f'isa = PBXGroup; children = {arr(products)}; name = Products; sourceTree = "<group>";')
mg=obj('main',f'isa = PBXGroup; children = {arr(list(dict.fromkeys(groups))+[pg])}; sourceTree = "<group>";')
cs=[obj('project'+m,f'isa = XCBuildConfiguration; name = {m}; buildSettings = {{CLANG_ENABLE_MODULES = YES; SWIFT_EMIT_LOC_STRINGS = YES;}};') for m in ['Debug','Release']]
cl=obj('projectconfigs',f'isa = XCConfigurationList; buildConfigurations = {arr(cs)}; defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;')
p=obj('project',f'isa = PBXProject; attributes = {{LastUpgradeCheck = 2600;}}; buildConfigurationList = {cl}; compatibilityVersion = "Xcode 14.0"; developmentRegion = de; knownRegions = (de, en, Base); mainGroup = {mg}; productRefGroup = {pg}; projectDirPath = ""; projectRoot = ""; targets = {arr(targets)};')
path=root/'Fokus.xcodeproj'; path.mkdir(exist_ok=True)
(path/'project.pbxproj').write_text('// !$*UTF8*$!\n{archiveVersion = 1; classes = {}; objectVersion = 56; objects = {\n'+ '\n'.join(k+' = {'+v+'};' for k,v in objects.items())+'\n}; rootObject = '+p+';}\n')
