import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { AuthService } from '../services/auth.service';
import { ProfileService } from '../services/profile.service';
import { FavoritesService, FavoriteProduct } from '../services/favorites.service';
import { CartService } from '../services/cart.service';
import { HeaderComponent } from "../header/header.component";
import { FooterComponent } from "../footer/footer.component";
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-profilepage',
  standalone: true,
  imports: [HeaderComponent, FooterComponent, ReactiveFormsModule, CommonModule],
  templateUrl: './profilepage.component.html',
  styleUrl: './profilepage.component.css',
})
export class ProfilepageComponent implements OnInit {
  activeTab: string = 'fiokkezeles';
  
  customerDataForm!: FormGroup;
  passwordForm!: FormGroup;
  deliveryDataForm!: FormGroup;

  userData: any = null;
  
  isUpdatingProfile: boolean = false;
  isChangingPassword: boolean = false;

  showOldPassword: boolean = false;
  showNewPassword: boolean = false;
  showConfirmPassword: boolean = false;

  // Rendeléseim modal
  isOrdersModalOpen: boolean = false;
  
  // Kedvencek modal
  isFavoritesModalOpen: boolean = false;
  
  // Kedvencek
  favorites: FavoriteProduct[] = [];
  loadingFavorites: boolean = false;
  
  // Mock rendelések
  mockOrders = [
    {
      id: 'ORD-2024-001',
      date: '2024.01.15.',
      status: 'Kiszállítva',
      statusClass: 'status-delivered',
      items: [
        { name: 'Wireless Bluetooth Fejhallgató', quantity: 1, price: 24990 },
        { name: 'USB-C Töltőkábel 2m', quantity: 2, price: 2990 }
      ],
      total: 30970
    },
    {
      id: 'ORD-2024-002',
      date: '2024.01.28.',
      status: 'Szállítás alatt',
      statusClass: 'status-shipping',
      items: [
        { name: 'Mechanikus Gaming Billentyűzet', quantity: 1, price: 45990 },
        { name: 'RGB Egérpad XL', quantity: 1, price: 8990 },
        { name: 'Gaming Egér 16000 DPI', quantity: 1, price: 19990 }
      ],
      total: 74970
    },
    {
      id: 'ORD-2024-003',
      date: '2024.02.02.',
      status: 'Feldolgozás alatt',
      statusClass: 'status-processing',
      items: [
        { name: 'Smart Watch Pro', quantity: 1, price: 89990 }
      ],
      total: 89990
    },
    {
      id: 'ORD-2023-047',
      date: '2023.12.20.',
      status: 'Kiszállítva',
      statusClass: 'status-delivered',
      items: [
        { name: 'Laptop Állvány Alumínium', quantity: 1, price: 12990 },
        { name: 'Webcam 1080p', quantity: 1, price: 15990 }
      ],
      total: 28980
    }
  ];

  constructor(
    private fb: FormBuilder,
    private router: Router,
    private authService: AuthService,
    private profileService: ProfileService,
    private favoritesService: FavoritesService,
    private cartService: CartService
  ) {}

  ngOnInit(): void {
    this.loadUserData();
    this.loadFavorites();
    
    // Feliratkozás a kedvencek változásaira
    this.favoritesService.favorites$.subscribe(favorites => {
      this.favorites = favorites;
      console.log('📋 Kedvencek frissítve:', this.favorites.length, 'db');
    });
  }

  loadUserData(): void {
    const currentUser = this.authService.getCurrentUser();
    
    if (currentUser) {
      const savedProfile = localStorage.getItem('currentUser');
      
      if (savedProfile) {
        this.userData = JSON.parse(savedProfile);
      } else {
        this.userData = {
          email: currentUser.email,
          username: currentUser.username,
          role: currentUser.role,
          telefonszam: '',
          vezetekNev: '',
          keresztNev: '',
          cim: { orszag: '', iranyitoszam: '', varos: '', utcaHazszam: '' }
        };
        localStorage.setItem('currentUser', JSON.stringify(this.userData));
      }
      
      this.initializeForms();
    } else {
      this.router.navigate(['/login']);
    }
  }

  loadFavorites(): void {
    this.loadingFavorites = true;
    this.favorites = this.favoritesService.getFavorites();
    this.loadingFavorites = false;
  }

  initializeForms(): void {
    this.customerDataForm = this.fb.group({
      email: [this.userData?.email || '', [Validators.required, Validators.email]],
      vezetekNev: [this.userData?.vezetekNev || '', Validators.required],
      keresztNev: [this.userData?.keresztNev || '', Validators.required]
    });

    this.passwordForm = this.fb.group({
      regiJelszo: ['', Validators.required],
      ujJelszo: ['', [Validators.required, Validators.minLength(8)]],
      ujJelszoMegerosites: ['', Validators.required]
    }, { validators: this.passwordMatchValidator });

    this.deliveryDataForm = this.fb.group({
      orszag: [this.userData?.cim?.orszag || '', Validators.required],
      iranyitoszam: [this.userData?.cim?.iranyitoszam || '', Validators.required],
      varos: [this.userData?.cim?.varos || '', Validators.required],
      utcaHazszam: [this.userData?.cim?.utcaHazszam || '', Validators.required],
      email: [this.userData?.email || '', [Validators.required, Validators.email]],
      telefonszam: [this.userData?.telefonszam || '', Validators.required]
    });
  }

  passwordMatchValidator(group: FormGroup): { [key: string]: boolean } | null {
    const newPassword = group.get('ujJelszo')?.value;
    const confirmPassword = group.get('ujJelszoMegerosites')?.value;
    return (newPassword !== confirmPassword) ? { passwordMismatch: true } : null;
  }

  togglePasswordVisibility(field: 'old' | 'new' | 'confirm'): void {
    if (field === 'old') this.showOldPassword = !this.showOldPassword;
    else if (field === 'new') this.showNewPassword = !this.showNewPassword;
    else this.showConfirmPassword = !this.showConfirmPassword;
  }

  getFullName(): string {
    return `${this.userData?.vezetekNev || ''} ${this.userData?.keresztNev || ''}`.trim() 
           || this.userData?.username || 'Felhasználó';
  }

  getFullAddress(): string {
    if (!this.userData?.cim) return '';
    const { varos, iranyitoszam, utcaHazszam } = this.userData.cim;
    return `${varos || ''}, ${iranyitoszam || ''}, ${utcaHazszam || ''}`.replace(/(^,\s*|,\s*$)/g, '');
  }

  hasDeliveryData(): boolean {
    if (!this.userData?.cim) return false;
    const { orszag, iranyitoszam, varos, utcaHazszam } = this.userData.cim;
    return !!(orszag || iranyitoszam || varos || utcaHazszam);
  }

  setActiveTab(tab: string): void {
    this.activeTab = tab;
  }

  isAdmin(): boolean {
    const role = this.userData?.role;
    if (!role) return false;
    const roleLower = role.toString().toLowerCase();
    return roleLower === 'admin' || roleLower === 'administrator';
  }

  goToAdminPage(): void {
    this.router.navigate(['/adminpage']);
  }

  onSubmit(): void {
    if (this.customerDataForm.valid && this.deliveryDataForm.valid) {
      const updatedData = {
        email: this.customerDataForm.value.email,
        vezetekNev: this.customerDataForm.value.vezetekNev,
        keresztNev: this.customerDataForm.value.keresztNev,
        telefonszam: this.deliveryDataForm.value.telefonszam,
        cim: {
          orszag: this.deliveryDataForm.value.orszag,
          iranyitoszam: this.deliveryDataForm.value.iranyitoszam,
          varos: this.deliveryDataForm.value.varos,
          utcaHazszam: this.deliveryDataForm.value.utcaHazszam
        }
      };

      this.isUpdatingProfile = true;

      this.profileService.updateUserProfile(updatedData).subscribe({
        next: (response) => {
          this.userData = { ...this.userData, ...updatedData };
          localStorage.setItem('currentUser', JSON.stringify(this.userData));
          alert('✅ Változások mentve!');
          this.isUpdatingProfile = false;
        },
        error: (error) => {
          this.isUpdatingProfile = false;
          this.userData = { ...this.userData, ...updatedData };
          localStorage.setItem('currentUser', JSON.stringify(this.userData));
          
          if (error.status === 401) {
            alert('❌ Érvénytelen token!');
            this.authService.logout();
            this.router.navigate(['/login']);
          } else {
            alert('⚠️ Adatok helyben mentve.');
          }
        }
      });
    } else {
      alert('⚠️ Töltsd ki az összes mezőt!');
    }
  }

  onPasswordChange(): void {
    if (!this.passwordForm.valid) {
      alert('⚠️ Töltsd ki az összes jelszó mezőt helyesen!');
      return;
    }

    const oldPassword = this.passwordForm.value.regiJelszo;
    const newPassword = this.passwordForm.value.ujJelszo;
    const confirmPassword = this.passwordForm.value.ujJelszoMegerosites;

    if (newPassword !== confirmPassword) {
      alert('❌ Az új jelszavak nem egyeznek!');
      return;
    }

    if (!this.authService.isLoggedIn()) {
      alert('❌ Lejárt a munkamenet, kérlek jelentkezz be újra!');
      this.authService.logout();
      this.router.navigate(['/login']);
      return;
    }

    this.isChangingPassword = true;

    this.authService.changePassword(oldPassword, newPassword).subscribe({
      next: (response) => {
        this.isChangingPassword = false;
        alert('✅ Jelszó sikeresen megváltoztatva!');
        this.passwordForm.reset();
        this.showOldPassword = false;
        this.showNewPassword = false;
        this.showConfirmPassword = false;
      },
      error: (error) => {
        this.isChangingPassword = false;
        
        let errorMsg = '❌ Hiba történt!';
        
        if (error.status === 401) {
          const errorBody = error.error;
          const message = (errorBody?.message || '').toLowerCase();
          
          if (message.includes('token') || message.includes('invalid token')) {
            errorMsg = '❌ Lejárt a munkamenet, kérlek jelentkezz be újra!';
            this.authService.logout();
            this.router.navigate(['/login']);
          } 
          else if (message.includes('old password') || message.includes('incorrect')) {
            errorMsg = '❌ A régi jelszó helytelen!';
          } 
          else {
            errorMsg = '❌ Hitelesítési hiba! Kérlek jelentkezz be újra.';
            this.authService.logout();
            this.router.navigate(['/login']);
          }
        } else if (error.status === 400) {
          const errorBody = error.error;
          if (errorBody?.status === 'WeakPassword') {
            errorMsg = '❌ A jelszó legalább 8 karakter hosszú kell legyen!';
          } else {
            errorMsg = '❌ Érvénytelen kérés!';
          }
        } else if (error.status === 404) {
          errorMsg = '❌ Felhasználó nem található!';
        } else if (error.status === 500) {
          errorMsg = '❌ Szerver hiba!';
        } else if (error.status === 0) {
          errorMsg = '❌ Nincs kapcsolat a szerverrel!';
        }
        
        alert(errorMsg);
      }
    });
  }

  resetChanges(): void {
    this.customerDataForm.patchValue({
      email: this.userData?.email || '',
      vezetekNev: this.userData?.vezetekNev || '',
      keresztNev: this.userData?.keresztNev || ''
    });

    this.passwordForm.reset();
    this.showOldPassword = false;
    this.showNewPassword = false;
    this.showConfirmPassword = false;

    this.deliveryDataForm.patchValue({
      orszag: this.userData?.cim?.orszag || '',
      iranyitoszam: this.userData?.cim?.iranyitoszam || '',
      varos: this.userData?.cim?.varos || '',
      utcaHazszam: this.userData?.cim?.utcaHazszam || '',
      email: this.userData?.email || '',
      telefonszam: this.userData?.telefonszam || ''
    });
    
    alert('Visszaállítva');
  }

  // Rendeléseim modal
  openOrdersModal(): void {
    this.isOrdersModalOpen = true;
    document.body.style.overflow = 'hidden';
  }

  closeOrdersModal(): void {
    this.isOrdersModalOpen = false;
    document.body.style.overflow = 'auto';
  }

  // Kedvencek modal
  openFavoritesModal(): void {
    this.loadFavorites();
    this.isFavoritesModalOpen = true;
    document.body.style.overflow = 'hidden';
  }

  closeFavoritesModal(): void {
    this.isFavoritesModalOpen = false;
    document.body.style.overflow = 'auto';
  }

  // Kedvenc eltávolítása
  removeFavorite(productId: number): void {
    this.favoritesService.removeFavorite(productId).subscribe({
      next: (response) => {
        console.log('✅ Kedvenc törölve:', productId);
        this.loadFavorites();
      },
      error: (err) => {
        console.error('❌ Hiba:', err);
        alert('Hiba történt!');
      }
    });
  }

  // Kosárba helyezés kedvencekből
  addFavoriteToCart(favorite: FavoriteProduct): void {
    if (!this.cartService.isLoggedIn()) {
      alert('A kosár használatához be kell jelentkezned!');
      this.router.navigate(['/login']);
      return;
    }

    const product: any = {
      id: favorite.id,
      name: favorite.name,
      price: favorite.price,
      pPrice: favorite.pPrice,
      stock: favorite.stock,
      imageUrl: favorite.imageUrl,
      categoryId: { id: favorite.categoryId, name: favorite.categoryName },
      brandId: { id: favorite.brandId, name: favorite.brandName },
      description: favorite.description
    };

    const success = this.cartService.addToCart(product, 1);
    if (success) {
      alert('✅ Termék hozzáadva a kosárhoz!');
    } else {
      alert('❌ Nem sikerült hozzáadni a kosárhoz!');
    }
  }

  // Termék képének URL-je
  getProductImageUrl(favorite: FavoriteProduct): string {
    return `http://127.0.0.1:8080/coreTech3-1.0-SNAPSHOT/webresources/products/${favorite.id}/images/1`;
  }

  // Ár formázás
  formatPrice(price: number): string {
    return Math.round(price).toLocaleString('hu-HU') + ' Ft';
  }

  // Készleten van-e
  isInStock(favorite: FavoriteProduct): boolean {
    return (favorite.stock ?? 0) > 0;
  }

  // Termék oldalra navigálás
  goToProduct(productId: number): void {
    this.closeFavoritesModal();
    this.router.navigate(['/product', productId]);
  }

  logout(): void {
    this.authService.logout();
    this.favoritesService.clearFavorites();
    this.router.navigate(['/mainpage']);
  }
}