import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { BehaviorSubject, Observable, of } from 'rxjs';
import { map, catchError, tap } from 'rxjs/operators';
import { Product } from './product.service';

export interface CartItem {
  item_id: number;
  product_id: number;
  quantity: number;
  product_name: string;
  product_price: number;
  product_p_price: number;
  product_image_url: string;
  product_stock: number;
  category_name: string;
  brand_name: string;
  line_total: number;
}

interface CartResponse {
  status: string;
  statusCode: number;
  items?: CartItem[];
  count?: number;
  message?: string;
}

@Injectable({
  providedIn: 'root'
})
export class CartService {
  private http = inject(HttpClient);
  private apiUrl = 'http://127.0.0.1:8080/coreTech3-1.0-SNAPSHOT/webresources/cart';
  
  private cartItemsSubject = new BehaviorSubject<CartItem[]>([]);
  cart$ = this.cartItemsSubject.asObservable();

  constructor() {
    console.log('🛒 CartService constructor called');
    console.log('🔐 isLoggedIn:', this.isLoggedIn());
    console.log('🎫 JWT token:', localStorage.getItem('JWT') ? 'EXISTS' : 'MISSING');
    
    // Load cart when service initializes
    if (this.isLoggedIn()) {
      console.log('✅ User logged in - loading cart from backend...');
      this.loadCart().subscribe({
        next: () => console.log('✅ Cart loaded in constructor'),
        error: (err) => console.error('❌ Error loading cart in constructor:', err)
      });
    } else {
      console.log('❌ User NOT logged in - skipping cart load');
    }
  }

  private getAuthHeaders() {
    const token = localStorage.getItem('JWT');
    return {
      headers: new HttpHeaders({
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      })
    };
  }

  isLoggedIn(): boolean {
    return !!localStorage.getItem('JWT');
  }

  // Load cart from backend
  loadCart(): Observable<CartItem[]> {
    if (!this.isLoggedIn()) {
      this.cartItemsSubject.next([]);
      return of([]);
    }

    console.log('🛒 Loading cart from backend...');
    return this.http.get<CartResponse>(this.apiUrl, this.getAuthHeaders()).pipe(
      tap(response => console.log('📦 Cart response:', response)),
      map(response => {
        if (response.status === 'Success' && response.items) {
          this.cartItemsSubject.next(response.items);
          console.log('✅ Cart loaded:', response.items.length, 'items');
          return response.items;
        }
        this.cartItemsSubject.next([]);
        return [];
      }),
      catchError(err => {
        console.error('❌ Error loading cart:', err);
        
        if (err.status === 405) {
          console.error('⚠️ 405 Method Not Allowed - Backend GET /cart endpoint NOT deployed!');
          console.error('⚠️ Backend developer must deploy CartController_COMPLETE.java');
        }
        
        this.cartItemsSubject.next([]);
        return of([]);
      })
    );
  }

  // Add product to cart
  addToCart(product: Product, quantity: number = 1): Observable<boolean> {
    if (!this.isLoggedIn()) {
      return of(false);
    }

    if (!product.stock || product.stock === 0) {
      return of(false);
    }

    const body = {
      productId: product.id,
      quantity: quantity
    };

    console.log('➕ Adding to cart:', body);
    
    return this.http.post<CartResponse>(this.apiUrl, body, this.getAuthHeaders()).pipe(
      tap(response => {
        console.log('📦 Add to cart response:', response);
        if (response.status === 'AddedToCart') {
          // Reload cart to get updated items
          this.loadCart().subscribe();
        }
      }),
      map(response => response.status === 'AddedToCart'),
      catchError(err => {
        console.error('❌ Error adding to cart:', err);
        return of(false);
      })
    );
  }

  // Update cart item quantity
  updateQuantity(itemId: number, quantity: number): Observable<boolean> {
    if (!this.isLoggedIn()) {
      return of(false);
    }

    const body = { quantity: quantity };
    
    console.log(`🔄 Updating item ${itemId} quantity to ${quantity}`);
    
    return this.http.put<CartResponse>(`${this.apiUrl}/${itemId}`, body, this.getAuthHeaders()).pipe(
      tap(response => {
        console.log('📦 Update quantity response:', response);
        if (response.status === 'QuantityUpdated' || response.status === 'ItemRemoved') {
          // Reload cart to get updated items
          this.loadCart().subscribe();
        }
      }),
      map(response => response.status === 'QuantityUpdated' || response.status === 'ItemRemoved'),
      catchError(err => {
        console.error('❌ Error updating quantity:', err);
        return of(false);
      })
    );
  }

  // Remove item from cart
  removeItem(itemId: number): Observable<boolean> {
    if (!this.isLoggedIn()) {
      return of(false);
    }

    console.log(`🗑️ Removing item ${itemId} from cart`);
    
    return this.http.delete<CartResponse>(`${this.apiUrl}/${itemId}`, this.getAuthHeaders()).pipe(
      tap(response => {
        console.log('📦 Remove item response:', response);
        if (response.status === 'ItemRemoved') {
          // Reload cart to get updated items
          this.loadCart().subscribe();
        }
      }),
      map(response => response.status === 'ItemRemoved'),
      catchError(err => {
        console.error('❌ Error removing item:', err);
        return of(false);
      })
    );
  }

  // Clear entire cart
  clearCart(): Observable<boolean> {
    if (!this.isLoggedIn()) {
      return of(false);
    }

    console.log('🧹 Clearing cart...');
    
    return this.http.put<CartResponse>(this.apiUrl, {}, this.getAuthHeaders()).pipe(
      tap(response => {
        console.log('📦 Clear cart response:', response);
        if (response.status === 'CartCleared') {
          this.cartItemsSubject.next([]);
        }
      }),
      map(response => response.status === 'CartCleared'),
      catchError(err => {
        console.error('❌ Error clearing cart:', err);
        return of(false);
      })
    );
  }

  // Get current cart items (synchronous)
  getCartItems(): CartItem[] {
    return this.cartItemsSubject.value;
  }

  // Get cart item count
  getCartCount(): number {
    return this.cartItemsSubject.value.length;
  }

  // Get total price
  getCartTotal(): number {
    return this.cartItemsSubject.value.reduce((total, item) => total + item.line_total, 0);
  }

  // Increase quantity helper
  increaseQuantity(itemId: number): Observable<boolean> {
    const item = this.cartItemsSubject.value.find(i => i.item_id === itemId);
    if (item) {
      return this.updateQuantity(itemId, item.quantity + 1);
    }
    return of(false);
  }

  // Decrease quantity helper
  decreaseQuantity(itemId: number): Observable<boolean> {
    const item = this.cartItemsSubject.value.find(i => i.item_id === itemId);
    if (item && item.quantity > 1) {
      return this.updateQuantity(itemId, item.quantity - 1);
    } else if (item && item.quantity === 1) {
      // If quantity is 1, removing it
      return this.removeItem(itemId);
    }
    return of(false);
  }
}