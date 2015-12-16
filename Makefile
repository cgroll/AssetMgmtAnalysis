
# gnu makefile for cfm

PROJ_DIR := .
PICS_DIR := pics
PRIV_DATA_DIR := financial_data
DATA_DIR := data
DATA_SRC := data_src
PICS_SRC := src

# enable docker image usage
PROJ_FULLPATH := $(HOME)/research/projects/AssetMgmtAnalysis
DOCK_HOME := /home/jovyan
DOCK_MOUNT := $(DOCK_HOME)/mount
DOCK_NAME := juliafinmetrix/jfinm_dev

############################################################
############## SPECIFY MAIN DATA FOR EACH PROCESSING SCRIPT:
############################################################

SCACAP_RAW_DATA := raw_data/scacap_E6AssetInfo.csv raw_data/scacap_universeE6.csv 
# SCACAP_PROCESSED_DATA := processed_data/scacap_E6DiscRets.csv
# MOMENTS_DATA := public_data/sampleMoments.csv

PRIV_DATA_NAMES := $(SCACAP_RAW_DATA)
# PRIV_DATA_NAMES := $(SCACAP_RAW_DATA) $(SCACAP_PROCESSED_DATA)
PRIV_DATA_FULL_NAMES := $(addprefix $(PRIV_DATA_DIR)/,$(PRIV_DATA_NAMES))

DATA_FULL_NAMES := $(PRIV_DATA_FULL_NAMES)
# DATA_FULL_NAMES := $(PRIV_DATA_FULL_NAMES) $(SCACAP_PROCESSED_DATA)

################################################
############## CREATION OF SVGS
################################################

# get list of all Julia source files for graphics
PICS_SCRIPTS_NAMES := $(notdir $(wildcard $(PICS_SRC)/*.jl))
PICS_FILE_NAMES := $(patsubst %.jl,%-1.svg,$(PICS_SCRIPTS_NAMES))
#RPICS_FILE_NAMES := missing_values-1.svg visualize_volatilities-1.svg market_trend_power-1.svg
PICS_FULL_NAMES := $(addprefix $(PICS_DIR)/,$(PICS_FILE_NAMES)) 

PICS_FILE_NAMES_FOR_DELETION := $(patsubst %.jl,%-*.svg,$(PICS_SCRIPTS_NAMES))

# add possibility to add other pictures also
ALL_PICS_FULL_NAMES := $(PICS_FULL_NAMES)

# hierarchically highest target:
all: $(DATA_FULL_NAMES) $(ALL_PICS_FULL_NAMES)
.PHONY: all

# phony target to create all data
.PHONY: data
data: $(DATA_FULL_NAMES)

###############################################
############## CREATION OF MAIN_DATA:
###############################################

# $(PRIV_DATA_DIR)/processed_data/SP500.csv: data_scripts/pick_sp500_data.jl $(PRIV_DATA_DIR)/raw_data/SP500.csv
#	julia data_scripts/pick_sp500_data.jl

# public_data/garch_norm_params.csv: data_scripts/garch_filtering.jl $(PRIV_DATA_DIR)/processed_data/SP500.csv
#	julia data_scripts/garch_filtering.jl

# recipe for graphics
$(addprefix $(PICS_DIR)/,$(PICS_FILE_NAMES)): $(PICS_DIR)/%-1.svg: $(PICS_SRC)/%.jl
	make data
	docker run --rm -v $(PROJ_FULLPATH):$(DOCK_MOUNT) -v $(HOME)/research/julia:/home/jovyan/research/julia -w $(DOCK_MOUNT) $(DOCK_NAME) julia -e 'include("$<")'


###############################################
############## REPORT GENERATION
###############################################

REPORT_DIR := backtesting/scacap_E6_2015_12_01

.PHONY: reports
reports: $(REPORT_DIR)/report_output/expWeighted.html $(REPORT_DIR)/report_output/data_report.html

$(REPORT_DIR)/report_output/expWeighted.html: $(REPORT_DIR)/strat_report_scripts/expWeighted_strategies.jl
	docker run --rm -v $(PROJ_FULLPATH):$(DOCK_MOUNT) -v $(HOME)/research/julia:/home/jovyan/research/julia -w $(DOCK_MOUNT)/$(REPORT_DIR) $(DOCK_NAME) julia -e 'include("strat_report_scripts/expWeighted_strategies.jl")'

$(REPORT_DIR)/report_output/data_report.html: $(REPORT_DIR)/strat_report_scripts/data_report.jl
	docker run --rm -v $(PROJ_FULLPATH):$(DOCK_MOUNT) -v $(HOME)/research/julia:/home/jovyan/research/julia -w $(DOCK_MOUNT)/$(REPORT_DIR) $(DOCK_NAME) julia -e 'include("strat_report_scripts/data_report.jl")'

.PHONY: singleReports
singleReports:
	docker run --rm -v $(PROJ_FULLPATH):$(DOCK_MOUNT) -v $(HOME)/research/julia:/home/jovyan/research/julia -w $(DOCK_MOUNT)/$(REPORT_DIR) $(DOCK_NAME) julia -e 'include("strat_report_scripts/singleStrategy_reports.jl")'



# 

# additional targets:
# TAGS files
# datasets
# executable files
# benchmark results
# unit tests

print-%:
	@echo '$*=$($*)'

# help - The default goal
.PHONY: help
help:
	$(MAKE) --print-data-base --question

.PHONY: nbconvert
nbconvert:
	julia utils/nbconvert.jl

.PHONY: clean
clean:
	rm -f Makefile~

# in case pics-3.svg has been deleted, while pics-1.svg still exists,
# updating rule for figures does not reproduce pics-3.svg
.PHONY: renew_all_julia_pics
renew_all_julia_pics:
	cd pics; rm -v $(PICS_FILE_NAMES_FOR_DELETION); cd ../; make

new:
	make
