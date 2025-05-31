import React, { useState } from 'react';
import axios from 'axios';
import Lottie from 'lottie-react';
import loaderData from '../assets/Loader animation.json';

function Chat() {
  const [identifier, setIdentifier] = useState('');
  const [userQuery, setUserQuery] = useState('');
  const [sqlQuery, setSqlQuery] = useState('');
  const [isCopied, setIsCopied] = useState(false);
  const [error, setError] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setIsLoading(true);
    
    try {
      const server = import.meta.env.VITE_SERVER_URL;
      console.log('Server URL:', server);
      console.log('Making request to:', `${server}/api/query`);
      
      const response = await axios.post(`${server}/api/query`, {
        collection_name: identifier,
        query: userQuery
      }, {
        headers: {
          'Content-Type': 'application/json'
        }
      });
      
      console.log('Response:', response.data.result);
      setSqlQuery(response.data.result);
    } catch (err) {
      console.error('Error details:', err);
      
      if (err.response) {
        // The request was made and the server responded with a status code
        // that falls out of the range of 2xx
        console.error('Response data:', err.response.data);
        console.error('Response status:', err.response.status);
        console.error('Response headers:', err.response.headers);
        setError(`Server error: ${err.response.status} - ${err.response?.data?.message || err.message}`);
      } else if (err.request) {
        // The request was made but no response was received
        console.error('No response received:', err.request);
        setError('No response from server. Please check your network connection.');
      } else {
        // Something happened in setting up the request
        setError(`Error: ${err.message}`);
      }
    } finally {
      setIsLoading(false);
    }
  };

  const copyToClipboard = async () => {
    try {
      await navigator.clipboard.writeText(sqlQuery);
      setIsCopied(true);
      setTimeout(() => setIsCopied(false), 2000);
    } catch (err) {
      console.error('Failed to copy text: ', err);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-purple-50 to-white py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-3xl mx-auto">
        <div className="text-center mb-12">
          <h1 className="text-4xl font-extrabold text-gray-900 mb-4">
            SQL Query Assistant
          </h1>
          <p className="text-xl text-gray-600 max-w-2xl mx-auto">
            Generate SQL queries using natural language descriptions
          </p>
        </div>

        <div className="space-y-8">
          <div className="bg-white shadow-sm rounded-xl p-6">
            <form onSubmit={handleSubmit} className="space-y-6">
              <div>
                <label htmlFor="identifier" className="block text-sm font-medium text-gray-700 mb-1">
                  Schema Identifier
                </label>
                <input
                  type="text"
                  id="identifier"
                  value={identifier}
                  onChange={(e) => setIdentifier(e.target.value)}
                  className="w-full px-4 py-3 rounded-lg border border-gray-300 focus:border-purple-500 focus:ring focus:ring-purple-200 focus:ring-opacity-50 transition duration-150 ease-in-out text-gray-700 bg-white"
                  placeholder="Enter your schema identifier"
                  required
                />
              </div>

              <div>
                <label htmlFor="userQuery" className="block text-sm font-medium text-gray-700 mb-1">
                  Describe Your Query
                </label>
                <textarea
                  id="userQuery"
                  value={userQuery}
                  onChange={(e) => setUserQuery(e.target.value)}
                  rows={4}
                  className="w-full px-4 py-3 rounded-lg border border-gray-300 focus:border-purple-500 focus:ring focus:ring-purple-200 focus:ring-opacity-50 transition duration-150 ease-in-out text-gray-700 bg-white"
                  placeholder="Describe what data you want to retrieve..."
                  required
                />
              </div>

              {error && (
                <div className="text-red-500 bg-red-50 px-4 py-2 rounded-lg flex items-center">
                  <svg className="w-5 h-5 mr-2" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clipRule="evenodd" />
                  </svg>
                  {error}
                </div>
              )}

              <button
                type="submit"
                disabled={isLoading}
                className="w-full px-4 py-3 bg-purple-600 text-white font-medium rounded-lg hover:bg-purple-700 focus:outline-none focus:ring-2 focus:ring-purple-500 focus:ring-offset-2 transition duration-150 ease-in-out disabled:opacity-50"
              >
                {isLoading ? 'Brewing Your SQL' : 'Generate SQL Query'}
              </button>
            </form>
          </div>

          {isLoading && (
            <div className="fixed inset-0 bg-black/30 backdrop-blur-sm flex items-center justify-center">
              <div className="bg-white p-8 rounded-xl shadow-xl max-w-md w-full">
                <Lottie
                  animationData={loaderData}
                  loop={true}
                  style={{ width: 200, height: 200, margin: '0 auto' }}
                />
                <div className="text-center mt-6 space-y-3">
                  <p className="text-xl font-semibold text-gray-800">Brewing Your SQL Magic ✨</p>
                  <p className="text-gray-600">
                    Our AI wizards are crafting the perfect query just for you...
                  </p>
                </div>
              </div>
            </div>
          )}

          {sqlQuery && (
            <div className="bg-white shadow-sm rounded-xl p-6">
              <div className="flex justify-between items-center mb-4">
                <h2 className="text-lg font-medium text-gray-900">Generated SQL Query</h2>
                <button
                  onClick={copyToClipboard}
                  className="px-4 py-2 bg-white border border-purple-300 rounded-lg text-sm font-medium text-white-600 hover:bg-purple-50 hover:border-purple-400 focus:outline-none focus:ring-2 focus:ring-purple-500 focus:ring-offset-2 transition duration-150 ease-in-out"
                >
                  {isCopied ? 'Copied!' : 'Copy'}
                </button>
              </div>
              <pre className="bg-gray-50 p-4 rounded-lg overflow-x-auto border border-gray-200">
                <code className="text-sm text-gray-800">{sqlQuery}</code>
              </pre>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

export default Chat;