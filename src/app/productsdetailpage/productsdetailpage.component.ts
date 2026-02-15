import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, Router } from '@angular/router';
import { ProductService, Product } from '../services/product.service';
import { ProductImageService } from '../services/product-image.service';
import { CartService } from '../services/cart.service';
import { FavoritesService } from '../services/favorites.service';
import { AuthService } from '../services/auth.service';
import { HeaderComponent } from '../header/header.component';
import { FooterComponent } from '../footer/footer.component';
import { ProductcardComponent } from '../productcard/productcard.component';

@Component({
  selector: 'app-productsdetailpage',
  standalone: true,
  imports: [CommonModule, HeaderComponent, FooterComponent, ProductcardComponent],
  templateUrl: './productsdetailpage.component.html',
  styleUrl: './productsdetailpage.component.css',
})
export class ProductsdetailpageComponent implements OnInit {
  product: Product | null = null;
  loading: boolean = true;
  
  // Image viewer
  productImages: string[] = [];
  selectedImageIndex: number = 0;
  imagesLoading: boolean = true;
  
  // Recommended products
  recommendedProducts: Product[] = [];
  
  // Quantity
  quantity: number = 1;

  // Favorites
  isFavorite: boolean = false;
  isTogglingFavorite: boolean = false;

  // Delivery dates
  storePickupDate: string = '';
  homeDeliveryDate: string = '';

  // Shipping dates
  foxpostDate: string = '';
  mplAutomataDate: string = '';
  coretechDate: string = '';
  mplFutarDate: string = '';
  dpdDate: string = '';

  private imageApiUrl = 'http://127.0.0.1:8080/coreTech3-1.0-SNAPSHOT/webresources/products';

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private productService: ProductService,
    private productImageService: ProductImageService,
    private cartService: CartService,
    private favoritesService: FavoritesService,
    private authService: AuthService
  ) {}

  ngOnInit(): void {
    this.calculateDeliveryDates();
    this.calculateShippingDates();
    
    this.route.params.subscribe(params => {
      const productId = +params['id'];
      if (productId) {
        this.loadProduct(productId);
        this.loadProductImages(productId);
        this.loadRecommendedProducts();
        this.checkIfFavorite(productId);
      }
    });

    // Feliratkozás a kedvencek változásaira
    this.favoritesService.favorites$.subscribe(() => {
      if (this.product) {
        this.isFavorite = this.favoritesService.isFavorite(this.product.id || 0);
      }
    });
  }

  calculateDeliveryDates(): void {
    const today = new Date();
    
    const storeDate = new Date(today);
    storeDate.setDate(today.getDate() + 3);
    this.storePickupDate = this.formatDateHu(storeDate);
    
    const homeDate = new Date(today);
    homeDate.setDate(today.getDate() + 5);
    this.homeDeliveryDate = this.formatDateHu(homeDate);
  }

  calculateShippingDates(): void {
    const today = new Date();
    this.foxpostDate = this.getRandomDeliveryDate(today);
    this.mplAutomataDate = this.getRandomDeliveryDate(today);
    this.coretechDate = this.getRandomDeliveryDate(today);
    this.mplFutarDate = this.getRandomDeliveryDate(today);
    this.dpdDate = this.getRandomDeliveryDate(today);
  }

  getRandomDeliveryDate(baseDate: Date): string {
    const randomDays = Math.floor(Math.random() * 4) + 3;
    const deliveryDate = new Date(baseDate);
    deliveryDate.setDate(baseDate.getDate() + randomDays);
    return this.formatDateHu(deliveryDate);
  }

  formatDateHu(date: Date): string {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const dayName = this.getDayName(date.getDay());
    return `${year}.${month}.${day}. ${dayName}`;
  }

  getDayName(dayIndex: number): string {
    const days = ['vasárnap', 'hétfő', 'kedd', 'szerda', 'csütörtök', 'péntek', 'szombat'];
    return days[dayIndex];
  }

  loadProduct(id: number): void {
    this.loading = true;
    this.productService.getProductById(id).subscribe({
      next: (product) => {
        this.product = product;
        this.loading = false;
        // Ellenőrzés kedvenc-e
        this.checkIfFavorite(id);
      },
      error: (err) => {
        console.error('Error loading product:', err);
        this.loading = false;
      }
    });
  }

  loadProductImages(productId: number): void {
    this.imagesLoading = true;
    this.productImageService.getProductImages(productId).subscribe({
      next: (images) => {
        this.productImages = images.length > 0 ? images : [`${this.imageApiUrl}/${productId}/images/1`];
        this.selectedImageIndex = 0;
        this.imagesLoading = false;
      },
      error: () => {
        this.productImages = [`${this.imageApiUrl}/${productId}/images/1`];
        this.imagesLoading = false;
      }
    });
  }

  loadRecommendedProducts(): void {
    this.productService.getAllProducts().subscribe({
      next: (products) => {
        const shuffled = products.sort(() => 0.5 - Math.random());
        this.recommendedProducts = shuffled.slice(0, 4);
      },
      error: (err) => {
        console.error('Error loading recommended products:', err);
      }
    });
  }

  checkIfFavorite(productId: number): void {
    this.isFavorite = this.favoritesService.isFavorite(productId);
  }

  toggleFavorite(): void {
    // Bejelentkezés ellenőrzés
    if (!this.authService.isLoggedIn()) {
      alert('A kedvencek használatához be kell jelentkezned!');
      this.router.navigate(['/login']);
      return;
    }

    if (!this.product) return;

    this.isTogglingFavorite = true;

    // Kedvenc váltás - most a TELJES TERMÉK ADATOKAT küldjük
    this.favoritesService.toggleFavorite(this.product).subscribe({
      next: (response) => {
        console.log('✅ Kedvenc váltva:', response);
        this.isFavorite = response.isFavorite;
        this.isTogglingFavorite = false;
        
        if (this.isFavorite) {
          alert('❤️ Hozzáadva a kedvencekhez!');
        } else {
          alert('💔 Eltávolítva a kedvencekből!');
        }
      },
      error: (err) => {
        console.error('❌ Hiba:', err);
        this.isTogglingFavorite = false;
        alert('Hiba történt!');
      }
    });
  }

  selectImage(index: number): void {
    this.selectedImageIndex = index;
  }

  nextImage(): void {
    if (this.productImages.length > 0) {
      this.selectedImageIndex = (this.selectedImageIndex + 1) % this.productImages.length;
    }
  }

  previousImage(): void {
    if (this.productImages.length > 0) {
      this.selectedImageIndex = (this.selectedImageIndex - 1 + this.productImages.length) % this.productImages.length;
    }
  }

  get currentImage(): string {
    return this.productImages[this.selectedImageIndex] || '';
  }

  increaseQuantity(): void {
    if (this.product && (!this.product.stock || this.quantity < this.product.stock)) {
      this.quantity++;
    }
  }

  decreaseQuantity(): void {
    if (this.quantity > 1) {
      this.quantity--;
    }
  }

  addToCart(): void {
    if (!this.cartService.isLoggedIn()) {
      alert('A kosár használatához be kell jelentkezned!');
      this.router.navigate(['/login']);
      return;
    }
    
    if (this.product && this.isInStock()) {
      const success = this.cartService.addToCart(this.product, this.quantity);
      if (success) {
        alert('✅ Termék hozzáadva a kosárhoz!');
      } else {
        alert('❌ Nem sikerült hozzáadni a kosárhoz!');
      }
    }
  }

  isInStock(): boolean {
    return this.product ? (this.product.stock ?? 0) > 0 : false;
  }

  formatPrice(price: number): string {
    return Math.round(price).toLocaleString('hu-HU') + ' Ft';
  }
}