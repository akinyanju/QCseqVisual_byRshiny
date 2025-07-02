
%% ===== CRON or Manual Launch =====
A[🛠 crawlerSeqMetrics.sh] --> B[gatherSequencingMetrics.sh]
A2[🛠 crawlerQCmetricsScript.sh] --> C[duckDBgatherwebQCmetrics.sh]

%% ===== CSV & DB Generation =====
B --> D[📄 SequencingMetrics.csv]
C -->|Loads CSV + QC| E[📂 GTdashboardMetrics.duckdb]

%% ===== Database pushed =====
E --> F[📤 Destination Server]
F --> G[📦 R/Shiny Dashboard App]

%% ===== Shiny App Structure =====
subgraph "Shiny App"
  G --> H1[app.R / server.R / UI.R / global.R]
  G --> H2[Libraries.R / configPaths.R / inputFile.R]
  G --> H3[auth.R (🔐 Login)]
  G --> H4[📄 access_log.csv, DashboardMetrics_log.csv, etc.]

  %% Landing Page (Sequencing Data)
  G --> I1[landingPageUI.R]
  G --> I2[landingPageServer.R]
  G --> I3[landingPagePlotCode.R]

  %% QC Dashboard
  G --> J1[dashboardSideBarUI.R]
  G --> J2[dashboardAuthHeaderUI.R]
  G --> J3[dashboardServer.R]
  G --> J4[DashboardPlotCode.R, SpeciesAlignmentPlot.R]

  %% Admin & Email
  G --> K1[AdminPage.R]
  G --> K2[userSelfEmailUpdate.R]
end
