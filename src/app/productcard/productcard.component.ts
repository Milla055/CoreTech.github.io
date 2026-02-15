import { Component, Input, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { ProductService, Product } from '../services/product.service';
import { CartService } from '../services/cart.service';

@Component({
  selector: 'app-productcard',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './productcard.component.html',
  styleUrl: './productcard.component.css'
})
export class ProductcardComponent implements OnInit {
  @Input() productId?: number;
  @Input() product?: Product | null;
  
  displayProduct: Product | null = null;
  loading: boolean = true;
  error: string | null = null;

  private imageApiUrl = 'http://127.0.0.1:8080/coreTech3-1.0-SNAPSHOT/webresources/products';

  constructor(
    private productService: ProductService,
    private cartService: CartService,
    private router: Router
  ) {}

  ngOnInit(): void {
    if (this.product) {
      this.displayProduct = this.product;
      this.loading = false;
    } 
    else if (this.productId) {
      this.loadProduct(this.productId);
    } 
    else {
      this.loadDefaultProduct();
    }
  }

  goToProductDetail(): void {
    if (this.displayProduct) {
      this.router.navigate(['/product', this.displayProduct.id]);
    }
  }

  getFirstImageUrl(productId: number): string {
    return `${this.imageApiUrl}/${productId}/images/1`;
  }

  loadProduct(id: number): void {
    this.loading = true;
    this.error = null;
    this.productService.getProductById(id).subscribe({
      next: (data) => {
        this.displayProduct = data;
        this.loading = false;
      },
      error: (error) => {
        console.error('Error loading product:', error);
        this.error = `Failed to load product (ID: ${id})`;
        this.loading = false;
      }
    });
  }

  loadDefaultProduct(): void {
    this.loading = true;
    this.error = null;
    this.productService.getAllProducts().subscribe({
      next: (products) => {
        if (products && products.length > 0) {
          this.displayProduct = products[0];
        } else {
          this.error = 'No products available';
        }
        this.loading = false;
      },
      error: (error) => {
        console.error('Error loading products:', error);
        this.error = 'Failed to load products';
        this.loading = false;
      }
    });
  }

  addToCart(event: Event): void {
    event.stopPropagation();
    
    if (!this.cartService.isLoggedIn()) {
      alert('A kosár használatához be kell jelentkezned!');
      this.router.navigate(['/login']);
      return;
    }
    
    if (this.displayProduct && this.isInStock()) {
      const success = this.cartService.addToCart(this.displayProduct, 1);
      if (success) {
        alert('Termék hozzáadva a kosárhoz!');
      } else {
        alert('Nem sikerült hozzáadni a kosárhoz!');
      }
    }
  }

  isInStock(): boolean {
    return this.displayProduct ? (this.displayProduct.stock ?? 0) > 0 : false;
  }

  formatPrice(price: number): string {
    return Math.round(price).toLocaleString('hu-HU') + ' Ft';
  }

  hasDiscount(): boolean {
    return this.displayProduct ? this.displayProduct.pPrice < this.displayProduct.price : false;
  }

  onImageError(event: any): void {
    event.target.src = 'assets/placeholder-product.png';
  }
}