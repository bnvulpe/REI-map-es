# Renewable Energy, Industry, and Innovation Map in Spain

**Spatial analysis of renewable energy infrastructures and their relation to population distribution, industrial emissions, protected areas, and public innovation programs.**

This project is divided into two parts. The first focuses on developing an interactive map to visualize industrial and renewable energy facilities, industrial CO₂ emissions, development projects, and elements of flora and hydrography. The creation process is detailed in the file `report_part_1_spanish`, and the structure of relevant files for reproduction and understanding is shown below:

main/
├── data/
│   ├── BTN100_TEMA7_ENERGIA_Y_CONDUCCIONES_2015
│   ├── btn_poi_energia
│   ├── densidad_poblacion_2023
│   ├── enp
│   ├── icons
│   ├── instalaciones_comercioderechoemision
│   ├── lineas_limite
│   ├── poi_sep_capas
│   ├── proyectos_sing
│   ├── rios
│   ├── styles
│   ├── zonas_GEI_digitalizacion
│   └── zonas_proyectos_singulares_digitalización
│   └── rei_map.gpkg
├── rendered_map/
│   ├── REI_1_150000.png
│   ├── REI_1_2300000.png
│   ├── REI_1_40000.png
│   └── REI_1_600000.png
└── 01_REI.qgz


In the second part, analyses were carried out to explore and address key questions based on the initially introduced data. To enrich the project, additional data sources were incorporated. The creation process is detailed in the files `report_part_2_1_spanish.pdf` and `report_part_2_2_spanish.pdf`. The structure of relevant files for reproduction and understanding is shown below:


main/
├── Analisis1.qgz
├── Analisis2.qgz
├── Analisis5_1.qgz
├── Analisis5_2.qgz
├── Analisis5_3.qgz
├── Analisis5_4.qgz
├── ...
├── Analisis8.qgz
├── Analisis9.qgz
├── report_part_2_1_spanish.pdf
├── report_part_2_2_spanish.pdf
├── data/part_2/
│   ├── espacios_protegidos_expuestos_gei
│   ├── grafo
│   ├── growth_pob
│   ├── instalaciones_riesgo_inundación
│   ├── masas_agua
│   ├── masas_agua_libes_presion
│   ├── mppf_canarias_tcm30-290950
│   ├── mppf_peninsulabaleares_tcm30-290949
│   ├── pob
│   ├── rios_libres_presion
│   ├── styles
│   ├── variacion_pob_2014_2023
│   ├── zonas_optimas
│   ├── zonas_pobladas_expuestas_gei
│   ├── gh_0_year_sarah2.tif
│   ├── solar_can.tif
│   ├── solar_pen.tif
│   └── wind_speed_regcan.tif
│   └── wind_speed.tif
├── plots_and_maps/
│   ├── 44.png
│   ├── 45.png
│   └── ...
│   └── 8_2.png
├── scripts/
│   ├── 05_optimal_areas.sql
│   ├── 06_corr_energy_population.sql
│   ├── 06_plots.ipynb
│   └── ...
│   └── zonas_criticas_electr.csv
└── tables/
    ├── chunks_into_table.sql
    ├── chunks_pob_into_table.sql
    ├── division_masas_agua.ipynb
    └── division_pob.ipynb
