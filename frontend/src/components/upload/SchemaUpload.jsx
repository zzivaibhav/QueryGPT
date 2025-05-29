import React, { useRef, useState } from "react";
import { useNavigate } from "react-router-dom";
import Lottie from 'lottie-react';
import loaderData from '../../assets/Loader - imposter.json';

function SchemaUpload({ onFileSelect, onDefinerChange }) {
  const navigate = useNavigate();
  const [selectedFile, setSelectedFile] = useState(null);
  const [error, setError] = useState("");
  const [definer, setDefiner] = useState("");
  const [isDragging, setIsDragging] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [uploadError, setUploadError] = useState("");
  const inputRef = useRef(null);

  const handleDrop = (e) => {
    e.preventDefault();
    setIsDragging(false);
    const file = e.dataTransfer.files[0];
    handleFile(file);
  };

  const handleFile = (file) => {
    if (!file) return;
    if (file.type !== "application/pdf") {
      setError("Please upload a PDF file.");
      setSelectedFile(null);
      onFileSelect && onFileSelect(null);
      return;
    }
    setError("");
    setSelectedFile(file);
    onFileSelect && onFileSelect(file);
  };

  const handleChange = (e) => {
    handleFile(e.target.files[0]);
  };

  const handleClick = () => {
    inputRef.current.click();
  };

  const handleDefinerChange = (e) => {
    setDefiner(e.target.value);
    onDefinerChange && onDefinerChange(e.target.value);
  };

  const handleDragOver = (e) => {
    e.preventDefault();
    setIsDragging(true);
  };

  const handleDragLeave = (e) => {
    e.preventDefault();
    setIsDragging(false);
  };

  const handleSubmit = async () => {
    if (!selectedFile || !definer) {
      setUploadError("Please select a file and provide a schema identifier.");
      return;
    }

    setIsLoading(true);
    setUploadError("");

    const formData = new FormData();
    formData.append('pdf_file', selectedFile);
    formData.append('collection_name', definer);

    try {
      const server = import.meta.env.VITE_SERVER_URL;
      const response = await fetch(`${server}/api/upload`, {
        method: 'POST',
        body: formData,
      });

      if (!response.ok) {
        throw new Error(`Upload failed: ${response.statusText}`);
      }

      const data = await response.json();
      // Clear form after successful upload
      setSelectedFile(null);
      setDefiner("");
      
      // Show a better success notification
      const notification = document.createElement('div');
      notification.className = 'fixed top-4 right-4 bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded flex items-center shadow-lg transition-all duration-500';
      notification.innerHTML = `
        <svg class="w-5 h-5 mr-2" fill="currentColor" viewBox="0 0 20 20">
          <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/>
        </svg>
        <span class="font-medium">Upload successful!</span>
      `;
      document.body.appendChild(notification);
      
      // Remove notification after 3 seconds
      setTimeout(() => {
        notification.style.opacity = '0';
        setTimeout(() => notification.remove(), 500);
      }, 3000);

      // Navigate to the chat page
      navigate('/chat');
    } catch (err) {
      setUploadError(err.message);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-purple-50 to-white py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-3xl mx-auto">
        <div className="text-center mb-12">
          <h1 className="text-4xl font-extrabold text-gray-900 mb-4">
            Upload Your SQL Schema
          </h1>
          <p className="text-xl text-gray-600 max-w-2xl mx-auto">
            Import your database schema PDF and start exploring with natural language queries
          </p>
        </div>

        <div className="space-y-8">
          <div
            className={`relative group ${
              isDragging ? 'border-purple-500 bg-purple-50' : 'border-gray-300 bg-white'
            } border-2 border-dashed rounded-2xl p-12 transition-all duration-200 ease-in-out hover:border-purple-400`}
            onClick={handleClick}
            onDrop={handleDrop}
            onDragOver={handleDragOver}
            onDragLeave={handleDragLeave}
          >
            <input
              type="file"
              accept="application/pdf"
              ref={inputRef}
              onChange={handleChange}
              className="hidden"
            />
            <div className="flex flex-col items-center">
              <div className={`p-4 rounded-full bg-purple-100 mb-6 transition-transform duration-200 ${isDragging ? 'scale-110' : 'group-hover:scale-105'}`}>
                <svg
                  className="w-12 h-12 text-purple-600"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth="2"
                    d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-8l-4-4m0 0L8 8m4-4v12"
                  />
                </svg>
              </div>
              
              {!selectedFile ? (
                <>
                  <h3 className="text-xl font-semibold text-gray-700 mb-2">
                    Drop your PDF schema here
                  </h3>
                  <p className="text-gray-500">
                    or <span className="text-purple-600 hover:text-purple-700 cursor-pointer">browse files</span>
                  </p>
                </>
              ) : (
                <div className="text-center">
                  <div className="flex items-center space-x-2 text-green-600 mb-2">
                    <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
                      <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                    </svg>
                    <span className="font-medium">File selected</span>
                  </div>
                  <p className="text-sm text-gray-600">{selectedFile.name}</p>
                </div>
              )}
              
              {error && (
                <div className="mt-4 text-red-500 bg-red-50 px-4 py-2 rounded-lg flex items-center">
                  <svg className="w-5 h-5 mr-2" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clipRule="evenodd" />
                  </svg>
                  {error}
                </div>
              )}
            </div>
          </div>

          <div className="bg-white shadow-sm rounded-xl p-6">
            <label className="block text-sm font-medium text-gray-700 mb-1" htmlFor="definer">
              Schema Identifier
            </label>
            <div className="mt-1">
              <input
                id="definer"
                type="text"
                className="w-full px-4 py-3 rounded-lg border border-gray-300 focus:border-purple-500 focus:ring focus:ring-purple-200 focus:ring-opacity-50 transition duration-150 ease-in-out text-gray-900"
                placeholder="e.g., 'Sales Database v1' or 'Customer Schema 2025'"
                value={definer}
                onChange={handleDefinerChange}
              />
              <p className="mt-2 text-sm text-gray-500 flex items-center">
                <svg className="w-4 h-4 mr-1 text-gray-400" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clipRule="evenodd" />
                </svg>
                Adding an identifier helps you find this schema later
              </p>
            </div>
          </div>

          {uploadError && (
            <div className="mt-4 text-red-500 bg-red-50 px-4 py-2 rounded-lg flex items-center">
              <svg className="w-5 h-5 mr-2" fill="currentColor" viewBox="0 0 20 20">
                <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clipRule="evenodd" />
              </svg>
              {uploadError}
            </div>
          )}

          <div className="flex justify-center">
            <button
              onClick={handleSubmit}
              disabled={!selectedFile || !definer || isLoading}
              className={`px-6 py-3 rounded-lg text-white font-medium 
                ${(!selectedFile || !definer || isLoading)
                  ? 'bg-gray-400 cursor-not-allowed'
                  : 'bg-purple-600 hover:bg-purple-700'
                } transition-colors duration-200 flex items-center`}
            >
              {isLoading ? (
                <div className="fixed inset-0 bg-black/30 backdrop-blur-sm flex items-center justify-center">
                  <div className="bg-white p-6 rounded-lg shadow-xl">
                    <Lottie
                      animationData={loaderData}
                      loop={true}
                      style={{ width: 200, height: 200 }}
                    />
                    <p className="text-center mt-4 text-gray-700 font-medium">Uploading...</p>
                  </div>
                </div>
              ) : (
                'Upload Schema'
              )}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

export default SchemaUpload;
