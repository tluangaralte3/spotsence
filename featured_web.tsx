"use client";

import { useState, useRef, useEffect } from "react";
import Image from "next/image";
import Link from "next/link";
import { Star, ChevronLeft, ChevronRight, MapPin } from "lucide-react";
import { db } from "@/lib/firebase/config";
import {
  collection,
  getDocs,
  query,
  where,
  orderBy,
  limit,
} from "firebase/firestore";

interface SpotCard {
  id: string;
  name: string;
  category: string;
  locationAddress?: string;
  averageRating?: number;
  popularity?: number;
  imagesUrl: string[];
  placeStory?: string;
  featured: boolean;
  status: string;
}

export default function FeaturedSpotsSection() {
  const scrollContainerRef = useRef<HTMLDivElement>(null);
  const [canScrollLeft, setCanScrollLeft] = useState(false);
  const [canScrollRight, setCanScrollRight] = useState(true);
  const [featuredSpots, setFeaturedSpots] = useState<SpotCard[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedCategory, setSelectedCategory] = useState<string>("all");
  const CACHE_DURATION = 10 * 60 * 1000; // 10 minutes

  // Fetch featured spots from Firestore
  useEffect(() => {
    const fetchFeaturedSpots = async () => {
      try {
        const CACHE_KEY = `featured_spots_${selectedCategory}`;

        // Check sessionStorage cache first
        const cached = sessionStorage.getItem(CACHE_KEY);
        if (cached) {
          const { data, timestamp } = JSON.parse(cached);
          const now = Date.now();

          // Use cache if still valid
          if (now - timestamp < CACHE_DURATION) {
            console.log(
              `Using cached featured spots data for ${selectedCategory}`,
            );
            setFeaturedSpots(data);
            setLoading(false);
            return;
          }
        }

        // Fetch from Firebase if cache miss or expired
        console.log(
          `Fetching fresh featured spots for ${selectedCategory} from Firebase`,
        );
        setLoading(true);
        const spotsRef = collection(db, "spots");

        // Build query based on selected category
        let q;
        if (selectedCategory === "all") {
          // Get all approved spots
          q = query(spotsRef, where("status", "==", "Approved"), limit(50));
        } else {
          // Filter by category
          q = query(
            spotsRef,
            where("status", "==", "Approved"),
            where("category", "==", selectedCategory),
            limit(50),
          );
        }

        const querySnapshot = await getDocs(q);
        let spots: SpotCard[] = querySnapshot.docs.map((doc) => ({
          id: doc.id,
          ...doc.data(),
        })) as SpotCard[];

        // Sort in memory: featured first, then by popularity
        spots.sort((a, b) => {
          // Featured spots first
          if (a.featured && !b.featured) return -1;
          if (!a.featured && b.featured) return 1;

          // Then by popularity (higher first)
          const popularityA = a.popularity || 0;
          const popularityB = b.popularity || 0;
          return popularityB - popularityA;
        });

        // Limit to 12 spots after sorting
        spots = spots.slice(0, 12);

        // Cache the data
        sessionStorage.setItem(
          CACHE_KEY,
          JSON.stringify({ data: spots, timestamp: Date.now() }),
        );

        setFeaturedSpots(spots);
      } catch (error) {
        console.error("Error fetching featured spots:", error);
        // Set empty array on error
        setFeaturedSpots([]);
      } finally {
        setLoading(false);
      }
    };

    fetchFeaturedSpots();
  }, [selectedCategory]);

  const checkScrollButtons = () => {
    if (scrollContainerRef.current) {
      const { scrollLeft, scrollWidth, clientWidth } =
        scrollContainerRef.current;
      setCanScrollLeft(scrollLeft > 0);
      setCanScrollRight(scrollLeft < scrollWidth - clientWidth - 10);
    }
  };

  useEffect(() => {
    checkScrollButtons();
    const container = scrollContainerRef.current;
    if (container) {
      container.addEventListener("scroll", checkScrollButtons);
      return () => container.removeEventListener("scroll", checkScrollButtons);
    }
  }, []);

  const scroll = (direction: "left" | "right") => {
    if (scrollContainerRef.current) {
      const scrollAmount = 400;
      scrollContainerRef.current.scrollBy({
        left: direction === "left" ? -scrollAmount : scrollAmount,
        behavior: "smooth",
      });
    }
  };

  return (
    <section className="bg-gray-50 py-16">
      <div className="container mx-auto px-4">
        {/* Header */}
        <div className="mb-8 flex items-end justify-between">
          <div>
            <h2 className="mb-2 text-3xl font-bold text-gray-900 md:text-4xl">
              Explore and unwind at Mizoram's
              <br />
              top relaxing spots
            </h2>
            <p className="text-gray-600">
              Discover hidden gems and popular destinations across Mizoram.{" "}
              <span className="font-medium text-emerald-600">
                Now with SpotSence.
              </span>
            </p>
          </div>
          <Link
            href="/category/all-spots"
            className="group flex items-center gap-2 rounded-full bg-emerald-600 px-6 py-3 text-sm font-semibold text-white transition-all hover:bg-emerald-700 hover:shadow-lg"
          >
            View All
            <ChevronRight className="h-4 w-4 transition-transform group-hover:translate-x-1" />
          </Link>
        </div>

        {/* Filter Tabs */}
        <div className="mb-8 flex items-center gap-3 overflow-x-auto pb-2">
          <button
            onClick={() => setSelectedCategory("all")}
            className={`rounded-full px-6 py-2.5 text-sm font-medium whitespace-nowrap transition-all ${
              selectedCategory === "all"
                ? "bg-gray-900 text-white hover:bg-gray-800"
                : "bg-white text-gray-700 hover:bg-gray-100"
            }`}
          >
            Popular nearby
          </button>
          <button
            onClick={() => setSelectedCategory("Mountains")}
            className={`rounded-full px-6 py-2.5 text-sm font-medium whitespace-nowrap transition-all ${
              selectedCategory === "Mountains"
                ? "bg-gray-900 text-white hover:bg-gray-800"
                : "bg-white text-gray-700 hover:bg-gray-100"
            }`}
          >
            Mountains
          </button>
          <button
            onClick={() => setSelectedCategory("Waterfalls")}
            className={`rounded-full px-6 py-2.5 text-sm font-medium whitespace-nowrap transition-all ${
              selectedCategory === "Waterfalls"
                ? "bg-gray-900 text-white hover:bg-gray-800"
                : "bg-white text-gray-700 hover:bg-gray-100"
            }`}
          >
            Waterfalls
          </button>
          <button
            onClick={() => setSelectedCategory("Cultural Sites")}
            className={`rounded-full px-6 py-2.5 text-sm font-medium whitespace-nowrap transition-all ${
              selectedCategory === "Cultural Sites"
                ? "bg-gray-900 text-white hover:bg-gray-800"
                : "bg-white text-gray-700 hover:bg-gray-100"
            }`}
          >
            Cultural Sites
          </button>
          <button
            onClick={() => setSelectedCategory("Viewpoints")}
            className={`rounded-full px-6 py-2.5 text-sm font-medium whitespace-nowrap transition-all ${
              selectedCategory === "Viewpoints"
                ? "bg-gray-900 text-white hover:bg-gray-800"
                : "bg-white text-gray-700 hover:bg-gray-100"
            }`}
          >
            Viewpoints
          </button>
          <button
            onClick={() => setSelectedCategory("Adventure")}
            className={`rounded-full px-6 py-2.5 text-sm font-medium whitespace-nowrap transition-all ${
              selectedCategory === "Adventure"
                ? "bg-gray-900 text-white hover:bg-gray-800"
                : "bg-white text-gray-700 hover:bg-gray-100"
            }`}
          >
            Adventure
          </button>
        </div>

        {/* Cards Container with Navigation */}
        <div className="relative">
          {/* Left Arrow */}
          {canScrollLeft && (
            <button
              onClick={() => scroll("left")}
              className="absolute top-1/2 left-0 z-10 -translate-x-1/2 -translate-y-1/2 rounded-full bg-white p-3 shadow-lg transition-all hover:scale-110 hover:shadow-xl"
              aria-label="Scroll left"
            >
              <ChevronLeft className="h-6 w-6 text-gray-700" />
            </button>
          )}

          {/* Right Arrow */}
          {canScrollRight && (
            <button
              onClick={() => scroll("right")}
              className="absolute top-1/2 right-0 z-10 translate-x-1/2 -translate-y-1/2 rounded-full bg-white p-3 shadow-lg transition-all hover:scale-110 hover:shadow-xl"
              aria-label="Scroll right"
            >
              <ChevronRight className="h-6 w-6 text-gray-700" />
            </button>
          )}

          {/* Scrollable Cards */}
          <div
            ref={scrollContainerRef}
            className="no-scrollbar flex gap-6 overflow-x-auto scroll-smooth"
          >
            {loading ? (
              <div className="min-w-[320px] flex-shrink-0 md:min-w-[360px]">
                <div className="flex items-center justify-center rounded-2xl bg-white py-16 shadow-md">
                  <div className="text-center">
                    <div className="mb-4 inline-block h-8 w-8 animate-spin rounded-full border-4 border-solid border-emerald-600 border-r-transparent"></div>
                    <p className="text-sm text-gray-600">Loading...</p>
                  </div>
                </div>
              </div>
            ) : featuredSpots.length === 0 ? (
              <div className="min-w-[320px] flex-shrink-0 md:min-w-[360px]">
                <div className="flex items-center justify-center rounded-2xl bg-white py-16 shadow-md">
                  <div className="text-center">
                    <MapPin className="mx-auto mb-4 h-16 w-16 text-gray-300" />
                    <p className="mb-2 text-lg font-semibold text-gray-900">
                      No spots found
                    </p>
                    <p className="text-sm text-gray-500">
                      {selectedCategory === "all"
                        ? "Check back soon!"
                        : `No ${selectedCategory} spots yet.`}
                    </p>
                  </div>
                </div>
              </div>
            ) : (
              featuredSpots.map((spot) => (
                <Link
                  key={spot.id}
                  href={`/spot-detail?id=${spot.id}`}
                  className="group block max-w-[320px] min-w-[320px] flex-shrink-0 md:max-w-[360px] md:min-w-[360px]"
                >
                  <div className="h-full overflow-hidden rounded-2xl bg-white shadow-md transition-all duration-300 hover:-translate-y-1 hover:shadow-xl">
                    {/* Image */}
                    <div className="relative h-64 w-full flex-shrink-0 overflow-hidden bg-gray-100">
                      {spot.imagesUrl && spot.imagesUrl.length > 0 ? (
                        <img
                          src={spot.imagesUrl[0]}
                          alt={spot.name}
                          className="absolute inset-0 h-full w-full object-cover transition-transform duration-300 group-hover:scale-105"
                        />
                      ) : (
                        <div className="absolute inset-0 bg-gradient-to-br from-emerald-400 to-blue-500">
                          <div className="flex h-full items-center justify-center text-white/20">
                            <MapPin className="h-20 w-20" />
                          </div>
                        </div>
                      )}
                      {spot.featured && (
                        <div className="absolute top-3 right-3 z-10 rounded-full bg-emerald-600 px-3 py-1 text-xs font-semibold text-white shadow-lg">
                          Featured
                        </div>
                      )}
                    </div>

                    {/* Content */}
                    <div className="p-5">
                      {/* Title and Rating */}
                      <div className="mb-2 flex items-start justify-between">
                        <div className="min-w-0 flex-1">
                          <h3 className="line-clamp-1 text-lg font-semibold text-gray-900">
                            {spot.name}
                          </h3>
                          <p className="line-clamp-1 text-sm text-gray-600">
                            {spot.locationAddress || spot.category}
                          </p>
                        </div>
                        {spot.averageRating !== undefined &&
                          spot.averageRating > 0 && (
                            <div className="ml-2 flex items-center gap-1">
                              <Star className="h-4 w-4 fill-amber-400 text-amber-400" />
                              <span className="text-sm font-semibold text-gray-900">
                                {spot.averageRating.toFixed(1)}
                              </span>
                            </div>
                          )}
                      </div>

                      {/* Description */}
                      <p className="mb-4 line-clamp-2 text-sm text-gray-600">
                        {spot.placeStory ||
                          `Explore the beauty of ${spot.name} in Mizoram.`}
                      </p>

                      {/* Category and Popularity */}
                      <div className="flex items-center justify-between border-t border-gray-100 pt-4">
                        <span className="text-sm font-medium text-emerald-600">
                          {spot.category}
                        </span>
                        {spot.popularity !== undefined && (
                          <div className="text-right">
                            <span className="text-lg font-bold text-gray-900">
                              {spot.popularity}
                            </span>
                            <span className="text-sm text-gray-600">/10</span>
                          </div>
                        )}
                      </div>
                    </div>
                  </div>
                </Link>
              ))
            )}
          </div>
        </div>
      </div>

      <style jsx global>{`
        .no-scrollbar::-webkit-scrollbar {
          display: none;
        }
        .no-scrollbar {
          -ms-overflow-style: none;
          scrollbar-width: none;
        }
      `}</style>
    </section>
  );
}
