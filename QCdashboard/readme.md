# Code Flow Overview

This diagram shows how the main scripts and modules interact in the Genome Technologies sequencing and QC metrics system.

```mermaid
graph TD

%% ===== Scheduled Crawlers =====
subgraph "Scheduled Crawlers (run separately)"
  A[🛠 crawlerSeqMetrics.sh]
  A2[🛠 crawlerQCmetricsScript.sh]
end

A --> B[gatherSequencingMetrics.sh]
A2 --> C[duckDBgatherwebQCmetrics.sh]

%% ===== CSV & DB Generation =====
B --> D[📄 SequencingMetrics.csv]
C -->|Loads CSV + QC| E[📂 GTdashboardMetrics.duckdb (Read-Only)]

%% ===== Database pushed =====
E --> F[📤 Destination Server (Read-Only Access)]

%% ===== Shiny App Structure on Destination Server =====
subgraph "Shiny Dashboard Application"
  F --> G1[app.R / server.R / UI.R / global.R]
  F --> G2[Libraries.R / configPaths.R / inputFile.R]
  F --> G3[auth.R (🔐 Login)]
  F --> G4[📄 Logs: access_log.csv, DashboardMetrics_log.csv, etc.]

  %% Landing Page (Sequencing Data)
  F --> H1[landingPageUI.R]
  F --> H2[landingPageServer.R]
  F --> H3[landingPagePlotCode.R]

  %% QC Dashboard Page
  F --> I1[dashboardSideBarUI.R]
  F --> I2[dashboardAuthHeaderUI.R]
  F --> I3[dashboardServer.R]
  F --> I4[DashboardPlotCode.R, SpeciesAlignmentPlot.R]

  %% Admin & Email Update Modules
  F --> J1[AdminPage.R]
  F --> J2[userSelfEmailUpdate.R]
end
