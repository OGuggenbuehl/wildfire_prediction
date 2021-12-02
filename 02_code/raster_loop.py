import glob, os, qgis.analysis, datetime
start = datetime.datetime.now()

vLayer = qgis.utils.iface.mapCanvas().currentLayer()
rasterpath = '/Users/oliverguggenbuehl/Documents/CalAdapt/avg_temp'
os.chdir(rasterpath)

for lyr in sorted(glob.glob("*.tif")):
    #print(lyr)
    rLayer = QgsRasterLayer(rasterpath+'/'+lyr, lyr)
    prefix = 't'+lyr[23:25:1]+lyr[25:27:1]
    print(prefix)
    #print(rLayer.isValid())
    qgis.analysis.QgsZonalStatistics(vLayer, rLayer, attributePrefix=prefix, rasterBand=1, stats=QgsZonalStatistics.Statistics(QgsZonalStatistics.Mean)).calculateStatistics(None)
    
end = datetime.datetime.now()
print(end - start)