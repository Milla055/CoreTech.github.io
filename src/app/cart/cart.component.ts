import { Component, OnInit, Input, Output, EventEmitter } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { CartService, CartItem } from '../services/cart.service';

@Component({
  selector: 'app-cart',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './cart.component.html',
  styleUrl: './cart.component.css',
})
export class CartComponent implements OnInit {
  @Input() isOpen: boolean = false;
  @Output() close = new EventEmitter<void>();

  cartItems: CartItem[] = [];
  cartTotal: number = 0;

  private imageApiUrl = 'http://127.0.0.1:8080/coreTech3-1.0-SNAPSHOT/webresources/products';

  constructor(
    private cartService: CartService,
    private router: Router
  ) {}

  ngOnInit(): void {
    console.log('🎨 Cart Component ngOnInit called');
    console.log('🔐 isLoggedIn:', this.isLoggedIn());
    
    // Load cart from backend on init
    if (this.isLoggedIn()) {
      console.log('✅ Loading cart in component...');
      this.cartService.loadCart().subscribe({
        next: (items) => console.log('✅ Cart loaded in component:', items.length, 'items'),
        error: (err) => console.error('❌ Error loading cart in component:', err)
      });
    } else {
      console.log('❌ Not logged in, skipping cart load');
    }
    
    // Subscribe to cart changes
    this.cartService.cart$.subscribe(items => {
      console.log('📦 Cart items updated:', items.length, 'items');
      this.cartItems = items;
      this.cartTotal = this.cartService.getCartTotal();
      console.log('💰 Cart total:', this.cartTotal);
    });
  }

  isLoggedIn(): boolean {
    return this.cartService.isLoggedIn();
  }

  getImageUrl(productId: number): string {
    return `${this.imageApiUrl}/${productId}/images/1`;
  }

  increaseQuantity(item: CartItem): void {
    this.cartService.increaseQuantity(item.item_id).subscribe({
      next: () => console.log('✅ Quantity increased'),
      error: (err) => console.error('❌ Error increasing quantity:', err)
    });
  }

  decreaseQuantity(item: CartItem): void {
    this.cartService.decreaseQuantity(item.item_id).subscribe({
      next: () => console.log('✅ Quantity decreased'),
      error: (err) => console.error('❌ Error decreasing quantity:', err)
    });
  }

  removeItem(item: CartItem): void {
    this.cartService.removeItem(item.item_id).subscribe({
      next: () => console.log('✅ Item removed'),
      error: (err) => console.error('❌ Error removing item:', err)
    });
  }

  clearCart(): void {
    if (confirm('Biztosan törölni szeretnéd az egész kosarat?')) {
      this.cartService.clearCart().subscribe({
        next: () => console.log('✅ Cart cleared'),
        error: (err) => console.error('❌ Error clearing cart:', err)
      });
    }
  }

  formatPrice(price: number): string {
    return Math.round(price).toLocaleString('hu-HU') + ' Ft';
  }

  goToProduct(productId: number): void {
    this.close.emit();
    this.router.navigate(['/product', productId]);
  }

  goToLogin(): void {
    this.close.emit();
    this.router.navigate(['/login']);
  }

  closeSidebar(): void {
    this.close.emit();
  }

  onBackdropClick(event: Event): void {
    if (event.target === event.currentTarget) {
      this.closeSidebar();
    }
  }

  checkout(): void {
    this.close.emit();
    this.router.navigate(['/checkout']);
  }
}