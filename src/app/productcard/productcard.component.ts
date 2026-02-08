import { Component, Input, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { ProductService, Product } from '../services/product.service';

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

  // Navigate to product image page
  goToProductImage(): void {
    if (this.displayProduct) {
      this.router.navigate(['/productimage', this.displayProduct.id]);
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
    event.stopPropagation(); // Ne navigáljon amikor kosárba teszi
    if (this.displayProduct) {
      this.productService.addToCart(this.displayProduct.id, 1).subscribe({
        next: (response) => {
          console.log('Product added to cart:', response);
          alert('Termék hozzáadva a kosárhoz!');
        },
        error: (error) => {
          console.error('Error adding to cart:', error);
          alert('Hiba történt a kosárhoz adás során!');
        }
      });
    }
  }

  formatPrice(price: number): string {
    return Math.round(price).toLocaleString('en-US') + ' Ft';
  }

  hasDiscount(): boolean {
    return this.displayProduct ? this.displayProduct.pPrice < this.displayProduct.price : false;
  }

  onImageError(event: any): void {
    event.target.src = 'assets/placeholder-product.png';
  }
}