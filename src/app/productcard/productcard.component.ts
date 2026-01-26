import { Component, Input, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ProductService, Product } from '../services/product.service';

@Component({
  selector: 'app-productcard',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './productcard.component.html',
  styleUrl: './productcard.component.css'
})
export class ProductcardComponent implements OnInit {
  @Input() productId?: number; // Optional: pass product ID from parent component
  
  product: Product | null = null;
  loading: boolean = true;
  error: string | null = null;

  constructor(private productService: ProductService) {}

  ngOnInit(): void {
    if (this.productId) {
      // If product ID is provided, fetch that specific product
      this.loadProduct(this.productId);
    } else {
      // Otherwise, you might want to load a default product or the first product
      this.loadDefaultProduct();
    }
  }

  loadProduct(id: number): void {
    this.loading = true;
    this.productService.getProductById(id).subscribe(
      (data) => {
        console.log('Product loaded:', data); // Debug log
        this.product = data;
        this.loading = false;
      },
      (error) => {
        console.error('Error loading product:', error);
        console.error('Error details:', error.error);
        console.error('Status:', error.status);
        console.error('URL tried:', error.url);
        this.error = 'Failed to load product - Check console for details';
        this.loading = false;
      }
    );
  }

  loadDefaultProduct(): void {
    this.loading = true;
    // Get all products and use the first one, or implement your own logic
    this.productService.getAllProducts().subscribe(
      (products) => {
        console.log('Products loaded:', products); // Debug log
        if (products && products.length > 0) {
          this.product = products[0]; // Use first product
        } else {
          this.error = 'No products available';
        }
        this.loading = false;
      },
      (error) => {
        console.error('Error loading products:', error);
        console.error('Error details:', error.error);
        console.error('Status:', error.status);
        console.error('URL tried:', error.url);
        this.error = 'Failed to load products - Check console for details';
        this.loading = false;
      }
    );
  }

  addToCart(): void {
    if (this.product) {
      this.productService.addToCart(this.product.id, 1).subscribe(
        (response) => {
          console.log('Product added to cart:', response);
          alert('Termék hozzáadva a kosárhoz!');
        },
        (error) => {
          console.error('Error adding to cart:', error);
          alert('Hiba történt a kosárhoz adás során!');
        }
      );
    }
  }

  formatPrice(price: number): string {
    return price.toLocaleString('hu-HU') + 'Ft';
  }

  hasDiscount(): boolean {
    return this.product ? this.product.pPrice < this.product.price : false;
  }
}