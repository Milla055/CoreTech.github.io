import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable, forkJoin, map, of } from 'rxjs';
import { catchError } from 'rxjs/operators';

export interface AdminStats {
  totalUsers: number;
  totalOrders: number;
  totalRevenue: number;
  totalProfit: number;
  totalAdmins: number;
  totalSubscribers: number;
}

export interface AdminUser {
  id: number;
  username: string;
  email: string;
  phone: string;
  role: string;
  created_at: string;
}

export interface Order {
  id: number;
  oderId?: number;
  userId: number;
  username?: string;
  totalPrice: number;
  status: string;
  createdAt: string;
}

export interface Review {
  id: number;
  productId: number;
  productName?: string;
  userId: number;
  username?: string;
  rating: number;
  comment: string;
  createdAt: string;
}

@Injectable({
  providedIn: 'root'
})
export class AdminService {
  private apiUrl = 'http://127.0.0.1:8080/coreTech3-1.0-SNAPSHOT/webresources';

  constructor(private http: HttpClient) {}

  // Helper method to get headers with JWT token
  private getAuthHeaders(): HttpHeaders {
    const token = localStorage.getItem('JWT');
    return new HttpHeaders({
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`
    });
  }

  // ==================== USERS ====================
  
  // Get user count
  getUserCount(): Observable<number> {
    return this.http.get<any>(`${this.apiUrl}/admin/users/getAllUsers`, { headers: this.getAuthHeaders() }).pipe(
      map(response => {
        console.log('getUserCount response:', response);
        // Backend returns { status, statusCode, users, count }
        return response.count || 0;
      }),
      catchError(err => {
        console.error('Error fetching user count:', err);
        return of(0);
      })
    );
  }

  getAllUsers(): Observable<any[]> {
    return this.http.get<any>(`${this.apiUrl}/admin/users/getAllUsers`, { headers: this.getAuthHeaders() }).pipe(
      map(response => {
        console.log('getAllUsers response:', response);
        return response.users || [];
      }),
      catchError(err => {
        console.error('Error fetching users:', err);
        return of([]);
      })
    );
  }

  getAdminUsers(): Observable<AdminUser[]> {
    return this.http.get<any>(`${this.apiUrl}/admin/users/filter/admins`, { headers: this.getAuthHeaders() }).pipe(
      map(response => {
        console.log('getAdmins response:', response);
        return response.admins || [];
      }),
      catchError(err => {
        console.error('Error fetching admins:', err);
        return of([]);
      })
    );
  }

  getCustomers(): Observable<any[]> {
    return this.http.get<any>(`${this.apiUrl}/admin/users/filter/customers`, { headers: this.getAuthHeaders() }).pipe(
      map(response => {
        console.log('getCustomers response:', response);
        return response.customers || [];
      }),
      catchError(err => {
        console.error('Error fetching customers:', err);
        return of([]);
      })
    );
  }

  getUserById(userId: number): Observable<any> {
    return this.http.get<any>(`${this.apiUrl}/admin/users/${userId}`, { headers: this.getAuthHeaders() }).pipe(
      map(response => response.user),
      catchError(err => {
        console.error('Error fetching user:', err);
        return of(null);
      })
    );
  }

  updateUserRole(userId: number, newRole: string): Observable<any> {
    return this.http.put<any>(`${this.apiUrl}/admin/users/role`, {
      userId: userId,
      newRole: newRole
    }, { headers: this.getAuthHeaders() });
  }

  deleteUser(userId: number): Observable<any> {
    return this.http.put<any>(`${this.apiUrl}/admin/users/delete/${userId}`, {}, { headers: this.getAuthHeaders() });
  }

  // ==================== ORDERS ====================
  
  getAllOrders(): Observable<any[]> {
    return this.http.get<any>(`${this.apiUrl}/admin/orders`, { headers: this.getAuthHeaders() }).pipe(
      map(response => {
        console.log('getAllOrders response:', response);
        return response.orders || [];
      }),
      catchError(err => {
        console.error('Error fetching orders:', err);
        return of([]);
      })
    );
  }

  updateOrderStatus(orderId: number, status: string): Observable<any> {
    return this.http.put<any>(`${this.apiUrl}/admin/orders/${orderId}/status`, {
      status: status
    }, { headers: this.getAuthHeaders() });
  }

  deleteOrder(orderId: number): Observable<any> {
    return this.http.put<any>(`${this.apiUrl}/admin/orders/delete/${orderId}`, {}, { headers: this.getAuthHeaders() });
  }

  // ==================== PRODUCTS ====================
  
  getAllProducts(): Observable<any[]> {
    return this.http.get<any[]>(`${this.apiUrl}/products`).pipe(
      map(response => {
        console.log('getAllProducts response:', response);
        // Ha tömb, akkor azt adjuk vissza, ha object akkor products mezőt
        if (Array.isArray(response)) {
          return response;
        }
        return (response as any).products || [];
      }),
      catchError(err => {
        console.error('Error fetching products:', err);
        return of([]);
      })
    );
  }

  createProduct(product: any): Observable<any> {
    return this.http.post<any>(`${this.apiUrl}/admin/products`, product, { headers: this.getAuthHeaders() });
  }

  updateProduct(productId: number, product: any): Observable<any> {
    return this.http.put<any>(`${this.apiUrl}/admin/products/${productId}`, product, { headers: this.getAuthHeaders() });
  }

  deleteProduct(productId: number): Observable<any> {
    return this.http.put<any>(`${this.apiUrl}/admin/products/delete/${productId}`, {}, { headers: this.getAuthHeaders() });
  }

  // ==================== BRANDS ====================
  
  createBrand(brand: { name: string; description: string; logoUrl: string }): Observable<any> {
    return this.http.post<any>(`${this.apiUrl}/admin/brands`, brand, { headers: this.getAuthHeaders() });
  }

  deleteBrand(brandId: number): Observable<any> {
    return this.http.put<any>(`${this.apiUrl}/admin/brands/delete/${brandId}`, {}, { headers: this.getAuthHeaders() });
  }

  // ==================== REVIEWS ====================
  
  getAllReviews(): Observable<any[]> {
    return this.http.get<any>(`${this.apiUrl}/reviews`).pipe(
      map(response => {
        console.log('getAllReviews response:', response);
        if (Array.isArray(response)) {
          return response;
        }
        return (response as any).reviews || [];
      }),
      catchError(err => {
        console.error('Error fetching reviews:', err);
        return of([]);
      })
    );
  }

  // ==================== ORDER ITEMS ====================
  
  getAllOrderItems(): Observable<any[]> {
    return this.http.get<any>(`${this.apiUrl}/orderitems`).pipe(
      map(response => {
        console.log('getAllOrderItems response:', response);
        if (Array.isArray(response)) {
          return response;
        }
        return (response as any).orderItems || (response as any).order_items || [];
      }),
      catchError(err => {
        console.error('Error fetching order items:', err);
        return of([]);
      })
    );
  }

  // ==================== DASHBOARD STATS ====================
  
  getDashboardStats(): Observable<AdminStats> {
    return forkJoin({
      users: this.getAllUsers(),
      admins: this.getAdminUsers(),
      orders: this.getAllOrders(),
      orderItems: this.getAllOrderItems(),
      products: this.getAllProducts()
    }).pipe(
      map(data => {
        console.log('Dashboard data received:', data);
        
        // Felhasználók számolása - csak aktívak (nem töröltek)
        const activeUsers = data.users.filter((u: any) => 
          u.is_deleted === 0 || u.is_deleted === null || u.is_deleted === false || !u.is_deleted
        );
        const totalUsers = activeUsers.length;
        
        // Adminok száma
        const totalAdmins = data.admins.length;
        
        // Feliratkozók számolása
        const subscribers = activeUsers.filter((u: any) => 
          u.is_subscripted === 1 || u.is_subscripted === true
        );
        const totalSubscribers = subscribers.length;
        
        // Rendelések száma
        const totalOrders = data.orders.length;
        
        // Termék térkép a profit számításához
        const productMap = new Map<number, any>();
        data.products.forEach((p: any) => {
          productMap.set(p.id, p);
        });

        // Bevétel és profit számítása az order_items alapján
        let totalRevenue = 0;
        let totalProfit = 0;

        data.orderItems.forEach((item: any) => {
          const productId = item.productId || item.product_id;
          const product = productMap.get(productId);
          const quantity = item.quantity || 1;
          const itemPrice = item.price || 0;
          
          // Bevétel = eladási ár * mennyiség
          const itemRevenue = itemPrice * quantity;
          totalRevenue += itemRevenue;
          
          // Profit = bevétel - beszerzési ár * mennyiség
          if (product) {
            const purchasePrice = product.pPrice || product.p_price || 0;
            const itemCost = purchasePrice * quantity;
            totalProfit += (itemRevenue - itemCost);
          }
        });

        console.log('Calculated stats:', {
          totalUsers,
          totalOrders,
          totalRevenue,
          totalProfit,
          totalAdmins,
          totalSubscribers
        });

        return {
          totalUsers,
          totalOrders,
          totalRevenue,
          totalProfit,
          totalAdmins,
          totalSubscribers
        };
      }),
      catchError(err => {
        console.error('Error calculating stats:', err);
        return of({
          totalUsers: 0,
          totalOrders: 0,
          totalRevenue: 0,
          totalProfit: 0,
          totalAdmins: 0,
          totalSubscribers: 0
        });
      })
    );
  }

  // Recent orders with username
  getRecentOrders(): Observable<Order[]> {
    return forkJoin({
      orders: this.getAllOrders(),
      users: this.getAllUsers()
    }).pipe(
      map(data => {
        const userMap = new Map<number, string>();
        data.users.forEach((u: any) => userMap.set(u.id, u.username));

        return data.orders
          .map((o: any) => ({
            id: o.id,
            oderId: o.id,
            userId: o.userId || o.user_id,
            username: userMap.get(o.userId || o.user_id) || 'Ismeretlen',
            totalPrice: o.totalPrice || o.total_price || 0,
            status: o.status || 'pending',
            createdAt: o.createdAt || o.created_at || ''
          }))
          .sort((a: Order, b: Order) => {
            const dateA = a.createdAt ? new Date(a.createdAt).getTime() : 0;
            const dateB = b.createdAt ? new Date(b.createdAt).getTime() : 0;
            return dateB - dateA;
          })
          .slice(0, 10);
      }),
      catchError(err => {
        console.error('Error fetching recent orders:', err);
        return of([]);
      })
    );
  }

  // Monthly sales for chart
  getMonthlySalesData(): Observable<any[]> {
    return this.getAllOrders().pipe(
      map(orders => {
        const monthlyData = new Map<string, { sales: number, orders: number }>();
        const months = ['Jan', 'Feb', 'Már', 'Ápr', 'Máj', 'Jún', 'Júl', 'Aug', 'Szep', 'Okt', 'Nov', 'Dec'];
        
        // Initialize all months
        months.forEach(m => monthlyData.set(m, { sales: 0, orders: 0 }));

        orders.forEach((order: any) => {
          const dateStr = order.createdAt || order.created_at;
          if (dateStr) {
            try {
              const date = new Date(dateStr);
              if (!isNaN(date.getTime())) {
                const monthIndex = date.getMonth();
                const monthName = months[monthIndex];
                
                const current = monthlyData.get(monthName)!;
                current.orders++;
                const price = order.totalPrice || order.total_price || 0;
                current.sales += price / 1000; // K Ft-ban
              }
            } catch (e) {
              console.warn('Invalid date:', dateStr);
            }
          }
        });

        return months.map(month => ({
          month,
          sales: Math.round(monthlyData.get(month)!.sales),
          orders: monthlyData.get(month)!.orders
        }));
      }),
      catchError(err => {
        console.error('Error fetching monthly sales:', err);
        const months = ['Jan', 'Feb', 'Már', 'Ápr', 'Máj', 'Jún', 'Júl', 'Aug', 'Szep', 'Okt', 'Nov', 'Dec'];
        return of(months.map(month => ({ month, sales: 0, orders: 0 })));
      })
    );
  }

  // Top selling products
  getTopProducts(): Observable<any[]> {
    return forkJoin({
      orderItems: this.getAllOrderItems(),
      products: this.getAllProducts()
    }).pipe(
      map(data => {
        const productMap = new Map<number, any>();
        data.products.forEach((p: any) => {
          productMap.set(p.id, p);
        });

        const productSales = new Map<number, { quantity: number, revenue: number }>();
        
        data.orderItems.forEach((item: any) => {
          const productId = item.productId || item.product_id;
          const quantity = item.quantity || 1;
          const price = item.price || 0;
          
          const current = productSales.get(productId) || { quantity: 0, revenue: 0 };
          current.quantity += quantity;
          current.revenue += price * quantity;
          productSales.set(productId, current);
        });

        const topProducts = Array.from(productSales.entries())
          .map(([productId, stats]) => {
            const product = productMap.get(productId);
            return {
              id: productId,
              name: product?.name || 'Ismeretlen termék',
              sales: stats.quantity,
              revenue: stats.revenue
            };
          })
          .sort((a, b) => b.sales - a.sales)
          .slice(0, 5);

        return topProducts;
      }),
      catchError(err => {
        console.error('Error fetching top products:', err);
        return of([]);
      })
    );
  }

  // Reviews with details
  getReviewsWithDetails(): Observable<Review[]> {
    return forkJoin({
      reviews: this.getAllReviews(),
      products: this.getAllProducts(),
      users: this.getAllUsers()
    }).pipe(
      map(data => {
        const productMap = new Map<number, string>();
        data.products.forEach((p: any) => productMap.set(p.id, p.name));
        
        const userMap = new Map<number, string>();
        data.users.forEach((u: any) => userMap.set(u.id, u.username));

        return data.reviews
          .filter((r: any) => !r.isDeleted && !r.is_deleted)
          .map((r: any) => ({
            id: r.id,
            productId: r.productId || r.product_id,
            productName: productMap.get(r.productId || r.product_id) || 'Ismeretlen',
            userId: r.userId || r.user_id,
            username: userMap.get(r.userId || r.user_id) || 'Ismeretlen',
            rating: r.rating,
            comment: r.comment,
            createdAt: r.createdAt || r.created_at || ''
          }))
          .sort((a: Review, b: Review) => {
            const dateA = a.createdAt ? new Date(a.createdAt).getTime() : 0;
            const dateB = b.createdAt ? new Date(b.createdAt).getTime() : 0;
            return dateB - dateA;
          });
      }),
      catchError(err => {
        console.error('Error fetching reviews:', err);
        return of([]);
      })
    );
  }
}