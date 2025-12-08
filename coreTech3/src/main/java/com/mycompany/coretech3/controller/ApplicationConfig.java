/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package com.mycompany.coretech3.controller;

/**
 *
 * @author kamil
 */
import java.util.Set;
import javax.ws.rs.core.Application;

@javax.ws.rs.ApplicationPath("webresources")
public class ApplicationConfig extends Application {

    @Override
    public Set<Class<?>> getClasses() {
        Set<Class<?>> resources = new java.util.HashSet<>();
        addRestResourceClasses(resources);
        return resources;
    }

    /**
     * Do not modify addRestResourceClasses() method. It is automatically
     * populated with all resources defined in the project. If required, comment
     * out calling this method in getClasses().
     */
    private void addRestResourceClasses(Set<Class<?>> resources) {
        resources.add(com.mycompany.coretech3.controller.AdminOrdersController.class);
        resources.add(com.mycompany.coretech3.controller.AdminUsersController.class);
        resources.add(com.mycompany.coretech3.controller.AnalyticsController.class);
        resources.add(com.mycompany.coretech3.controller.OrdersController.class);
        resources.add(com.mycompany.coretech3.controller.UsersController.class);
        
    }

}

