import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute } from '@angular/router';
import { ProductImageService } from '../services/product-image.service';

@Component({
  selector: 'app-productimage',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './productimage.component.html',
  styleUrl: './productimage.component.css',
})
export class ProductimageComponent implements OnInit {
  productId: number = 0;
  productName: string = '';
  
  selectedImageIndex: number = 0;
  isLoading: boolean = false;
  loadedImages: string[] = [];
  
  constructor(
    private route: ActivatedRoute,
    private productImageService: ProductImageService
  ) {}
  
  ngOnInit() {
    // Kiolvasni a productId-t az URL-ből: /productimage/50
    this.route.params.subscribe(params => {
      this.productId = +params['id']; // + konvertálja stringből számmá
      console.log('Product ID from URL:', this.productId);
      if (this.productId) {
        this.loadImages();
      }
    });
  }
  
  private loadImages(): void {
    this.isLoading = true;
    this.productImageService.getProductImages(this.productId)
      .subscribe({
        next: (images) => {
          console.log('Images loaded:', images);
          this.loadedImages = images.length > 0 ? images : [];
          this.selectedImageIndex = 0;
          this.isLoading = false;
        },
        error: (err) => {
          console.error('Error loading images:', err);
          this.loadedImages = [];
          this.isLoading = false;
        }
      });
  }
  
  selectImage(index: number): void {
    this.selectedImageIndex = index;
  }
  
  nextImage(): void {
    if (this.loadedImages.length > 0) {
      this.selectedImageIndex = (this.selectedImageIndex + 1) % this.loadedImages.length;
    }
  }
  
  previousImage(): void {
    if (this.loadedImages.length > 0) {
      this.selectedImageIndex = (this.selectedImageIndex - 1 + this.loadedImages.length) % this.loadedImages.length;
    }
  }
  
  get currentImage(): string {
    return this.loadedImages[this.selectedImageIndex] || '';
  }
  
  get displayImages(): string[] {
    return this.loadedImages;
  }
  
  get hasImages(): boolean {
    return this.loadedImages.length > 0;
  }
}