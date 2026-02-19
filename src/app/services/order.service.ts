import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

export interface OrderData {
  userId: number;
  addressId?: number;
  totalPrice: number;
  status: string;
  items: OrderItem[];
  // Address data (if creating new address)
  address?: {
    street: string;
    city: string;
    postalCode: string;
    country: string;
  };
}

export interface OrderItem {
  productId: number;
  quantity: number;
  price: number;
}

export interface Order {
  id: number;
  userId: number;
  addressId: number;
  totalPrice: number;
  status: string;
  createdAt: string;
  items?: OrderItem[];
}

@Injectable({
  providedIn: 'root'
})
export class OrderService {
  private apiUrl = 'http://127.0.0.1:8080/coreTech3-1.0-SNAPSHOT/webresources';

  constructor(private http: HttpClient) {}

  private getAuthHeaders(): HttpHeaders {
    const token = localStorage.getItem('JWT');
    return new HttpHeaders({
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`
    });
  }

  // Create new order
  createOrder(orderData: OrderData): Observable<any> {
    return this.http.post<any>(`${this.apiUrl}/orders`, orderData, {
      headers: this.getAuthHeaders()
    });
  }

  // Get user's orders
  getUserOrders(): Observable<Order[]> {
    return this.http.get<any>(`${this.apiUrl}/orders/user`, {
      headers: this.getAuthHeaders()
    }).pipe(
      map(response => {
        if (response.status === 'Success' && response.orders) {
          return response.orders;
        }
        return [];
      })
    );
  }

  // Get order by ID
  getOrderById(orderId: number): Observable<Order> {
    return this.http.get<any>(`${this.apiUrl}/orders/${orderId}`, {
      headers: this.getAuthHeaders()
    }).pipe(
      map(response => {
        if (response.status === 'Success' && response.order) {
          return response.order;
        }
        throw new Error('Order not found');
      })
    );
  }

  // Create address (returns address ID)
  createAddress(address: any): Observable<number> {
    return this.http.post<any>(`${this.apiUrl}/addresses`, address, {
      headers: this.getAuthHeaders()
    }).pipe(
      map(response => {
        if (response.status === 'Success' && response.addressId) {
          return response.addressId;
        }
        throw new Error('Failed to create address');
      })
    );
  }

  // Get user's addresses
  getUserAddresses(): Observable<any[]> {
    return this.http.get<any>(`${this.apiUrl}/addresses/user`, {
      headers: this.getAuthHeaders()
    }).pipe(
      map(response => {
        if (response.status === 'Success' && response.addresses) {
          return response.addresses;
        }
        return [];
      })
    );
  }
}