/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package com.mycompany.coretech3.scheduler;

import com.mycompany.coretech3.service.OrdersService;
import javax.ejb.Schedule;
import javax.ejb.Singleton;
import javax.ejb.Startup;
import javax.inject.Inject;

/**
 *
 * @author kamil
 */@Singleton
@Startup
public class OrderStatusScheduler {

//    @Inject
//    OrdersService ordersService;
//
//    @Schedule(hour="*", minute="*/3", second="0", persistent=false)
//    public void autoUpdateOrders() {
//        ordersService.autoProgressOrders();
//    }
}

