# **Case Study: Creating an Interactive Geospatial Dashboard for Routine Immunization**

## **Introduction**

### **Project Overview**

The project aimed to develop an interactive geospatial dashboard using Shiny, providing insights into Routine Immunization (RI) and Cold Chain Equipment (CCE) functionality across different states in Nigeria.

### **Objectives**

1.  Visualize the distribution of Cold Chain Equipment.

2.  Provide a breakdown of Routine Immunization services in each state.

3.  Create an interactive map allowing users to explore functionality details by clicking on specific states.

## **Technology Stack**

### **Shiny Modules**

We employed modularization to enhance code organization and maintainability. Two key modules were created:

-   **`riMapModule`**: Manages the interactive map and state functionality details.

-   **`riOverviewModule`**: Presents an overview of CCE and RI services.

### **Key Packages**

-   **sf:** Used for handling geospatial data.

-   **leaflet:** Employed for creating interactive maps within the Shiny application.

-   **bslib:** Provided Bootstrap-themed layouts for the UI.

-   **thematic:** Utilized for customizing the CSS theme.

## **Project Structure**

### **Modularization**

The project was structured to promote code modularity, with separate R scripts for each Shiny module (**`riMapModule`** and **`riOverviewModule`**), promoting code reusability and ease of maintenance.

### **Directory Layout**

```         
markdownCopy code
```

[`-`]{.underline}`app.R - R/   - riMapModule.R   - riOverviewModule.R - data/   - health_care_facilities_geo.rds`

## **Development Process**

### **Data Processing**

Geospatial data on health care facilities was loaded and processed using the **`sf`** package. CCE and RI service statistics were calculated for each state.

### **Interactive Maps**

The **`leaflet`** package was employed to create interactive maps. Each state was represented as a circle marker with clusters to drill-down to hospital (facility) level with pop-up details.

### **Shiny Modules**

Shiny modules were utilized to encapsulate logic and UI elements for both the overview and map sections, fostering code modularity and maintainability.

### **User Interface (UI)**

The **`bslib`** package was instrumental in customizing the UI appearance. Thematic styling provided a visually appealing and user-friendly interface.

## **Results and Impact**

### **Overview**

-   The dashboard offers a high-level overview of CCE distribution and RI services across Nigeria.

-   Users can quickly assess the functionality status of each state's CCE.

### **Interactive Maps**

-   The interactive map enables users to click on states to view detailed information about RI and CCE functionality.

-   Custom markers and pop-ups enhance the visual experience.

## **Future Enhancements**

-   **Data Updates:** Implement mechanisms to update data dynamically, ensuring real-time insights.

-   **User Authentication:** Integrate user authentication for personalized access to sensitive information.

-   **Additional Layers:** Explore the possibility of adding additional map layers for more comprehensive insights.

## **Conclusion**

The Shiny application has successfully transformed complex geospatial data into an intuitive and interactive dashboard. The modular structure, use of Shiny modules, and thoughtful design choices have contributed to the project's success. As we continue to evolve the application, we anticipate providing even more valuable insights into Routine Immunization and Cold Chain Equipment functionality in Nigeria.
