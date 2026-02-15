import { Injectable } from '@angular/core';
import { BehaviorSubject } from 'rxjs';
import { Product } from './product.service';

export interface CartItem {
  product: Product;
  quantity: number;
}

@Injectable({
  providedIn: 'root'
})
export class CartService {
  private cartItems: CartItem[] = [];
  private cartSubject = new BehaviorSubject<CartItem[]>([]);
  
  cart$ = this.cartSubject.asObservable();

  constructor() {
    this.loadCartFromStorage();
  }

  private loadCartFromStorage(): void {
    // Only load if user is logged in
    if (this.isLoggedIn()) {
      const stored = localStorage.getItem('cart');
      if (stored) {
        this.cartItems = JSON.parse(stored);
        this.cartSubject.next(this.cartItems);
      }
    }
  }

  private saveCartToStorage(): void {
    localStorage.setItem('cart', JSON.stringify(this.cartItems));
    this.cartSubject.next(this.cartItems);
  }

  isLoggedIn(): boolean {
    return !!localStorage.getItem('user') || !!localStorage.getItem('JWT');
  }

  addToCart(product: Product, quantity: number = 1): boolean {
    if (!this.isLoggedIn()) {
      return false;
    }

    if (product.stock === 0) {
      return false;
    }

    const existingItem = this.cartItems.find(item => item.product.id === product.id);
    
    if (existingItem) {
      const newQty = existingItem.quantity + quantity;
      existingItem.quantity = product.stock ? Math.min(newQty, product.stock) : newQty;
    } else {
      this.cartItems.push({ product, quantity });
    }

    this.saveCartToStorage();
    return true;
  }

  removeFromCart(productId: number): void {
    this.cartItems = this.cartItems.filter(item => item.product.id !== productId);
    this.saveCartToStorage();
  }

  updateQuantity(productId: number, quantity: number): void {
    const item = this.cartItems.find(item => item.product.id === productId);
    if (item) {
      if (quantity <= 0) {
        this.removeFromCart(productId);
      } else {
        item.quantity = item.product.stock ? Math.min(quantity, item.product.stock) : quantity;
        this.saveCartToStorage();
      }
    }
  }

  getCartItems(): CartItem[] {
    return this.cartItems;
  }

  getCartTotal(): number {
    return this.cartItems.reduce((total, item) => total + (item.product.pPrice * item.quantity), 0);
  }

  getCartCount(): number {
    return this.cartItems.reduce((count, item) => count + item.quantity, 0);
  }

  clearCart(): void {
    this.cartItems = [];
    localStorage.removeItem('cart');
    this.cartSubject.next(this.cartItems);
  }
}